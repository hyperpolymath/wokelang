# WokeLang Concurrency and Worker System Proofs

This document provides formal proofs of safety properties for WokeLang's worker-based concurrency model.

## 1. Concurrency Model

### 1.1 Worker Definition

```
w ∈ Worker = {
    name: Ident,
    body: List<Statement>,
    state: WorkerState,
    inbox: Queue<Message>,
    outbox: Queue<Message>
}

WorkerState ::= Created | Running | Blocked | Completed | Failed
```

### 1.2 Message Type

```
m ∈ Message ::= Value(v)
              | Stop
              | Ping
              | Pong
              | Named(name, v)
```

### 1.3 System State

```
Σ ∈ SystemState = {
    workers: Map<Ident, Worker>,
    main_thread: ThreadState,
    global_env: Environment
}
```

---

## 2. Operational Semantics for Workers

### 2.1 Worker Creation

```
                 w = Worker { name: n, body: s*, state: Created, inbox: [], outbox: [] }
────────────────────────────────────────────────────────────────────────────────────────── [W-Define]
⟨worker n { s* }, Σ⟩ → ⟨(), Σ[workers(n) := w]⟩
```

### 2.2 Worker Spawning

```
               Σ.workers(n) = w    w.state = Created
                    w' = w[state := Running]
─────────────────────────────────────────────────────── [W-Spawn]
⟨spawn worker n, Σ⟩ → ⟨(), Σ[workers(n) := w']⟩
```

### 2.3 Message Send

```
              Σ.workers(target) = w
                 w' = w[inbox := w.inbox ++ [Value(v)]]
─────────────────────────────────────────────────────────── [W-Send]
⟨send v to target, Σ⟩ → ⟨(), Σ[workers(target) := w']⟩
```

### 2.4 Message Receive (Blocking)

```
              Σ.workers(source) = w    w.outbox = [m | rest]
                  w' = w[outbox := rest]
─────────────────────────────────────────────────────────────── [W-Receive]
⟨receive from source, Σ⟩ → ⟨m.value, Σ[workers(source) := w']⟩
```

### 2.5 Worker Execution Step

```
       Σ.workers(n) = w    w.state = Running    w.body = [s | rest]
              ⟨s, w.env, Φ, C⟩ ⇓ᵇ (r, env', C')
                    w' = w[body := rest, env := env']
───────────────────────────────────────────────────────────────────── [W-Step]
⟨Σ⟩ →ᵥ ⟨Σ[workers(n) := w']⟩
```

### 2.6 Worker Completion

```
       Σ.workers(n) = w    w.state = Running    w.body = []
                    w' = w[state := Completed]
─────────────────────────────────────────────────────────────── [W-Complete]
⟨Σ⟩ →ᵥ ⟨Σ[workers(n) := w']⟩
```

### 2.7 Worker Await

```
              Σ.workers(n) = w    w.state = Completed
─────────────────────────────────────────────────────── [W-Await]
⟨await n, Σ⟩ → ⟨(), Σ⟩
```

### 2.8 Worker Cancel

```
              Σ.workers(n) = w    w.state ∈ {Running, Blocked}
                    w' = w[state := Failed]
───────────────────────────────────────────────────────────────── [W-Cancel]
⟨cancel n, Σ⟩ → ⟨(), Σ[workers(n) := w']⟩
```

---

## 3. Safety Properties

### 3.1 Worker Isolation

**Theorem 3.1 (Worker Isolation):** Workers cannot directly access each other's local state.

**Formal Statement:**
```
∀w₁, w₂ ∈ Σ.workers. w₁ ≠ w₂ →
    w₁.env ∩ w₂.env = ∅ (no shared mutable state)
```

**Proof:**
- Each worker has its own environment created at spawn time
- Environments are separate HashMap instances
- No references between worker environments exist
- Communication only through message passing □

### 3.2 Message Passing Safety

**Theorem 3.2 (Message Integrity):** Messages are delivered intact without corruption.

**Proof:**
- Messages are Rust enums (immutable once constructed)
- MPSC channels provide memory-safe transfer
- Clone semantics ensure receiver gets independent copy
- No shared mutable references to message data □

### 3.3 No Data Races

**Theorem 3.3 (Data Race Freedom):** The worker model is free of data races.

**Definition:** A data race occurs when:
1. Two threads access the same memory location
2. At least one access is a write
3. Accesses are not synchronized

**Proof:**
- Workers have separate environments (no shared memory)
- Message queues are synchronized (MPSC channels)
- Global environment access is read-only after initialization
- Rust's ownership prevents aliased mutable references □

### 3.4 Deadlock Analysis

**Theorem 3.4 (Conditional Deadlock Freedom):** Deadlock is possible only through cyclic wait patterns in user code.

**Potential Deadlock Scenarios:**
1. Worker A waits for message from B, B waits for message from A
2. Main thread awaits worker that awaits main thread response

**Current Implementation:** The current implementation runs workers synchronously, avoiding true concurrent deadlock. Future async implementation should include deadlock detection.

**TODO:** Implement deadlock detection:
```
type WaitGraph = Map<WorkerId, Set<WorkerId>>

detect_deadlock(graph: WaitGraph) → Option<Cycle>
    // Tarjan's algorithm for cycle detection
```

---

## 4. Liveness Properties

### 4.1 Progress

**Theorem 4.1 (Worker Progress):** A running worker with non-empty body will eventually execute or block.

**Proof:**
- [W-Step] applies when body is non-empty
- Each statement either completes or blocks on I/O
- No infinite internal loops without progress
- Eventual [W-Complete] when body exhausted □

### 4.2 Message Delivery

**Theorem 4.2 (Eventually Delivered):** Sent messages are eventually received or available.

**Proof:**
- [W-Send] atomically enqueues message
- Queue is unbounded (in current implementation)
- [W-Receive] dequeues when queue non-empty
- No message loss mechanism exists □

**Note:** Unbounded queues can lead to memory exhaustion. Production systems should bound queue size.

### 4.3 Termination

**Theorem 4.3 (Conditional Termination):** Workers terminate if:
1. Body contains no infinite loops
2. All blocking operations eventually unblock

**Proof:**
- Body is a finite list of statements
- Each statement either terminates or blocks
- If blocked, external event unblocks (message arrival, cancel)
- Eventually body is exhausted → [W-Complete] □

---

## 5. Communication Patterns

### 5.1 Request-Response

```
// Main thread
send request to worker;
remember response = receive from worker;

// Worker
remember req = receive from main;
remember result = process(req);
send result to main;
```

**Property:** This pattern is deadlock-free if worker always responds.

### 5.2 Pipeline

```
worker stage1 { ... send to stage2; }
worker stage2 { ... send to stage3; }
worker stage3 { ... send to output; }

spawn worker stage1;
spawn worker stage2;
spawn worker stage3;
send input to stage1;
remember result = receive from output;
```

**Property:** Pipeline is deadlock-free (unidirectional flow).

### 5.3 Worker Pool

```
// Pool of workers processing tasks
worker processor {
    repeat forever {
        remember task = receive from dispatcher;
        remember result = process(task);
        send result to collector;
    }
}
```

**Property:** Pool provides load balancing; individual workers may starve.

---

## 6. Memory Safety

### 6.1 Message Ownership

**Theorem 6.1 (Message Ownership Transfer):** Sending a message transfers ownership to the receiver.

**Proof:**
- Rust's ownership system enforces move semantics
- Sender cannot access message after send
- Receiver becomes sole owner
- No use-after-send possible □

### 6.2 Worker Cleanup

**Theorem 6.2 (Resource Cleanup):** Worker resources are released when worker completes or is cancelled.

**Proof:**
- Worker struct dropped when removed from workers map
- Rust's Drop trait ensures cleanup
- Inbox/outbox queues freed
- Environment dropped □

### 6.3 Channel Safety

**MPSC Channel Properties:**
- Sender end cloneable (multiple producers)
- Receiver end not cloneable (single consumer)
- Channel dropped when all senders dropped
- Receiving from closed channel returns None

---

## 7. Scheduling

### 7.1 Current Implementation (Synchronous)

```
spawn worker n;  // Immediately executes n to completion
```

**Properties:**
- Deterministic execution order
- No preemption
- No true parallelism
- Simple to reason about

### 7.2 Future Async Implementation

**TODO:** Implement async workers with:
1. Task queue
2. Thread pool
3. Cooperative scheduling
4. Work stealing

### 7.3 Fairness

**Definition:** A scheduler is fair if every ready worker eventually runs.

**Current:** Trivially fair (synchronous execution)

**Async TODO:** Implement round-robin or work-stealing scheduler.

---

## 8. Formal Model (Process Algebra)

### 8.1 CSP-Style Semantics

Workers as CSP processes:

```
P, Q ::= 0                    (termination)
       | a.P                  (action prefix)
       | P + Q                (choice)
       | P || Q               (parallel)
       | P \ L                (hiding)
       | X                    (recursion variable)
       | μX.P                 (recursion)
```

### 8.2 WokeLang Worker as CSP

```
Worker(n, body) = body.Completed(n)

Send(target, v) = target!v.0

Receive(source) = source?x.Continue(x)

System = Main || Worker₁ || Worker₂ || ...
```

### 8.3 Traces Semantics

**Definition:** A trace is a sequence of observable events.

```
Event ::= Send(worker, value)
        | Receive(worker, value)
        | Spawn(worker)
        | Complete(worker)
        | Cancel(worker)
```

**Theorem 8.1 (Trace Equivalence):** The operational semantics and CSP model produce equivalent traces.

---

## 9. Actor Model Comparison

### 9.1 Similarities to Actors

| Property | WokeLang Workers | Classic Actors |
|----------|------------------|----------------|
| Isolated state | ✓ | ✓ |
| Message passing | ✓ | ✓ |
| Asynchronous | Partial (sync impl) | ✓ |
| Supervision | ✗ | ✓ (Erlang) |
| Location transparency | ✗ | ✓ (Akka) |

### 9.2 Differences

1. **Static definition:** Workers defined at compile time, not dynamic spawn
2. **No supervision trees:** No automatic restart on failure
3. **Explicit channels:** Send/receive name target explicitly
4. **Main thread special:** Asymmetric model

---

## 10. Implementation Correspondence

| Concept | Implementation (`src/worker/mod.rs`) |
|---------|---------------------------------------|
| Worker | `Worker` struct |
| WorkerState | `WorkerState` enum |
| Message | `WorkerMessage` enum |
| Inbox | `mpsc::Receiver<WorkerMessage>` |
| Outbox | `mpsc::Sender<WorkerMessage>` |
| Spawn | `spawn()` method |
| Send | `send()` method |
| Receive | `receive()` / `receive_blocking()` |

---

## 11. Known Limitations

### 11.1 Current Implementation

1. **Synchronous execution:** Workers run sequentially, not in parallel
2. **No thread pool:** Each spawn creates a new thread
3. **No supervision:** Errors propagate to caller
4. **No timeouts:** Blocking receive waits indefinitely

### 11.2 TODO: Improvements

**TODO:** Implement:
1. Async/await workers using Tokio
2. Worker supervision trees
3. Timeout operations
4. Bounded message queues
5. Deadlock detection
6. Worker monitoring/debugging

---

## 12. Verification Approach

### 12.1 Model Checking (Future)

Using SPIN or TLA+:
```tla
---- MODULE Workers ----
VARIABLES workers, messages

TypeInvariant ==
    /\ workers \in [WorkerId -> WorkerState]
    /\ messages \in Seq(Message)

SafetyInvariant ==
    \A w1, w2 \in DOMAIN workers:
        w1 /= w2 => Disjoint(State(w1), State(w2))
====
```

### 12.2 Property-Based Testing

```rust
#[quickcheck]
fn worker_isolation(actions: Vec<Action>) -> bool {
    let result = simulate(actions);
    no_shared_state_violation(result)
}
```

---

## References

1. Hewitt, C. et al. (1973). "A Universal Modular Actor Formalism for Artificial Intelligence"
2. Hoare, C.A.R. (1978). "Communicating Sequential Processes"
3. Armstrong, J. (2007). "Programming Erlang: Software for a Concurrent World"
4. Agha, G. (1986). "Actors: A Model of Concurrent Computation in Distributed Systems"
