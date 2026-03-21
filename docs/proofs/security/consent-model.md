# WokeLang Consent Model: Formal Specification

This document provides a complete formal specification of the consent system, including temporal logic properties, interactive semantics, and persistent storage proofs.

## 1. Consent Domain

### 1.1 Permission Language

```
π ∈ Permission ::= resource ":" action ":" target
                 | resource ":" action ":" "*"

resource ∈ Resource ::= "file" | "network" | "execute" | "env" | "system" | "crypto"
action ∈ Action ::= "read" | "write" | "connect" | "run" | "access"
target ∈ Target ::= Path | Host | Command | Variable | "*"
```

Examples:
```
"file:read:/etc/passwd"
"network:connect:api.example.com"
"execute:run:*"
```

### 1.2 Consent Duration

```
d ∈ Duration ::= Once           (single use)
               | Session        (until program terminates)
               | Day            (24 hours from grant)
               | Week           (7 days from grant)
               | Forever        (no expiration)
```

### 1.3 Stored Consent

```
consent ∈ StoredConsent = {
    permission: Permission,
    granted: Bool,
    granted_at: Timestamp,
    duration: Duration,
    metadata: Map<String, String>
}
```

### 1.4 Consent Store State

```
Σ ∈ ConsentStore = {
    consents: Map<Permission, StoredConsent>,
    file_path: Path,
    dirty: Bool
}
```

---

## 2. Consent Semantics

### 2.1 Validity Function

```
is_valid : StoredConsent × Timestamp → Bool
is_valid(c, now) =
    c.granted ∧
    case c.duration of
        Once → false                          -- Already used
        Session → true                        -- Valid for session
        Day → now - c.granted_at < 86400s
        Week → now - c.granted_at < 604800s
        Forever → true
```

### 2.2 Lookup Semantics

```
lookup : ConsentStore × Permission × Timestamp → Option<Bool>
lookup(Σ, π, now) =
    case Σ.consents.get(π) of
        None → None                           -- No cached decision
        Some(c) →
            if is_valid(c, now) then Some(c.granted)
            else None                         -- Expired
```

### 2.3 Store Semantics

```
store : ConsentStore × Permission × Bool × Duration → ConsentStore
store(Σ, π, granted, d) =
    let c = {
        permission: π,
        granted: granted,
        granted_at: now(),
        duration: d,
        metadata: {}
    } in
    Σ[consents := Σ.consents.insert(π, c)]
     [dirty := true]
```

---

## 3. Interactive Consent Protocol

### 3.1 Protocol States

```
State ::= Initial
        | Cached(result: Bool)
        | Prompting
        | Granted
        | Denied
        | Error(msg: String)
```

### 3.2 Protocol Transitions

```
          lookup(Σ, π, now) = Some(b)
────────────────────────────────────────── [P-Cached]
⟨Initial, Σ, π⟩ → ⟨Cached(b), Σ, π⟩

        lookup(Σ, π, now) = None
────────────────────────────────────────── [P-NeedPrompt]
⟨Initial, Σ, π⟩ → ⟨Prompting, Σ, π⟩

           user_response = "y"
────────────────────────────────────────── [P-UserGrant]
⟨Prompting, Σ, π⟩ → ⟨Granted, store(Σ, π, true, Session), π⟩

           user_response ≠ "y"
────────────────────────────────────────── [P-UserDeny]
⟨Prompting, Σ, π⟩ → ⟨Denied, store(Σ, π, false, Session), π⟩

        Cached(true) ∨ Granted
────────────────────────────────────────── [P-Allow]
⟨_, Σ, π⟩ → execute protected operation

        Cached(false) ∨ Denied
────────────────────────────────────────── [P-Block]
⟨_, Σ, π⟩ → skip protected operation
```

### 3.3 Protocol Properties

**Theorem 3.1 (Protocol Completeness):** Every consent request terminates in either Granted, Denied, Cached(true), or Cached(false).

**Proof:** The protocol has no cycles:
- Initial → Cached(_) or Initial → Prompting
- Prompting → Granted or Prompting → Denied
- All terminal states are decision states □

**Theorem 3.2 (Determinism):** The consent protocol is deterministic given fixed user responses.

**Proof:** Each state has exactly one outgoing transition for any given condition. The lookup function is deterministic. User responses are treated as external input. □

---

## 4. Persistent Consent Store

### 4.1 Serialization Format

```
serialize : ConsentStore → Bytes
deserialize : Bytes → Result<ConsentStore, Error>
```

The on-disk format (TOML):
```toml
[consents."file:read:/tmp"]
granted = true
granted_at = 1704067200
duration = "Session"
```

### 4.2 Persistence Invariants

**Invariant 4.1 (Round-Trip):** `deserialize(serialize(Σ)) = Ok(Σ')`  where Σ ≈ Σ' (semantically equivalent)

**Invariant 4.2 (Crash Recovery):** If the program crashes after `store()` but before `persist()`, the store file remains consistent (possibly stale).

**Invariant 4.3 (Atomic Write):** `persist()` uses atomic file operations (write-to-temp + rename).

### 4.3 File Integrity

```
persist : ConsentStore → IO<Result<(), Error>>
persist(Σ) =
    let temp = Σ.file_path ++ ".tmp" in
    let data = serialize(Σ) in
    write_file(temp, data);
    rename(temp, Σ.file_path);
    Ok(())
```

**Theorem 4.1 (Persistence Safety):** The persist operation either fully succeeds or leaves the file unchanged.

**Proof:** The rename operation is atomic on POSIX systems. If any step fails before rename, the original file is unmodified. □

---

## 5. Security Properties

### 5.1 Consent Integrity

**Theorem 5.1 (Consent Unforgability):** A program cannot create consent records without user interaction (in interactive mode).

**Proof:** The only path to `store(..., true, ...)` in interactive mode goes through [P-UserGrant], which requires `user_response = "y"`. This is an external input. □

### 5.2 Consent Non-Repudiation

**Theorem 5.2 (Audit Trail):** All consent decisions are recorded with timestamps.

**Proof:** The `store()` function always sets `granted_at: now()`. Combined with the audit log in the capability system, all decisions are traceable. □

### 5.3 Temporal Consistency

**Theorem 5.3 (Monotonic Time):** Consent validity is monotonically decreasing over time for time-limited consents.

**Proof:** The `is_valid()` function computes `now - granted_at < threshold`. As `now` increases, this becomes false eventually for Day and Week durations. □

### 5.4 Privacy Protection

**Theorem 5.4 (Consent Isolation):** Consent decisions for one permission do not affect other permissions.

**Proof:** The consent store uses permission as key. `lookup(Σ, π₁, _)` and `lookup(Σ, π₂, _)` access different entries when π₁ ≠ π₂. □

---

## 6. Formal Logic Encoding

### 6.1 Temporal Logic Properties

Using LTL (Linear Temporal Logic):

**Property 6.1 (Eventual Decision):**
```
G(request(π) → F(granted(π) ∨ denied(π)))
```
(Every request eventually gets a decision)

**Property 6.2 (Consent Persistence):**
```
G(granted(π, Forever) → G(valid(π)))
```
(Forever grants remain valid)

**Property 6.3 (Expiration):**
```
G(granted(π, Day) → F(¬valid(π)))
```
(Day grants eventually expire)

### 6.2 CTL Properties

Using CTL (Computation Tree Logic):

**Property 6.4 (Possibility of Grant):**
```
AG(request(π) → EF(granted(π)))
```
(It's always possible to grant any request)

**Property 6.5 (Possibility of Deny):**
```
AG(request(π) → EF(denied(π)))
```
(It's always possible to deny any request)

---

## 7. Consent UI Security

### 7.1 UI Spoofing Prevention

**Requirement 7.1:** The consent prompt must be distinguishable from program output.

**Implementation:** Uses system-level prefix `🔐` and different output stream (stderr vs stdout).

### 7.2 Clickjacking Prevention

**Requirement 7.2:** Rapid successive consent requests should be throttled.

**TODO:** Implement rate limiting for consent prompts:
```
throttle : Timestamp → IO<()>
throttle(last_prompt) =
    if now() - last_prompt < 500ms then
        sleep(500ms - (now() - last_prompt))
```

### 7.3 Phishing Resistance

**Requirement 7.3:** Permission strings must be validated and normalized.

```
normalize : String → Permission
normalize(s) =
    let parts = s.split(':') in
    if valid_resource(parts[0]) and valid_action(parts[1]) then
        Permission { resource: parts[0], action: parts[1], target: parts[2] }
    else
        error("Invalid permission format")
```

---

## 8. Comparison with Other Models

### 8.1 vs. Android Permissions

| Aspect | WokeLang Consent | Android Permissions |
|--------|------------------|---------------------|
| Granularity | Per-resource | Per-category |
| Timing | Runtime (JIT) | Install-time + Runtime |
| Revocation | Immediate | Requires app restart |
| Expiration | Configurable | None |
| Scope | Function-level | App-level |

### 8.2 vs. Browser Permissions

| Aspect | WokeLang Consent | Browser Permissions |
|--------|------------------|---------------------|
| Persistence | Configurable | Per-origin |
| UI | CLI prompt | Modal dialog |
| Categories | Extensible | Fixed set |
| Delegation | Scope-based | Not supported |

### 8.3 vs. Capability Systems

| Aspect | WokeLang Consent | Pure Capabilities |
|--------|------------------|-------------------|
| User Interaction | Required | Not required |
| Forgery Prevention | By protocol | By unforgability |
| Revocation | Explicit | Drop reference |
| Audit | Built-in | External |

---

## 9. Implementation Correspondence

| Concept | Implementation (`src/security/consent.rs`) |
|---------|---------------------------------------------|
| StoredConsent | `StoredConsent` struct |
| ConsentStore | `ConsentStore` struct |
| Duration | `ConsentDuration` enum |
| is_valid | `is_valid()` method |
| lookup | `check()` method |
| store | `record()` method |
| persist | `save()` method |
| deserialize | `load()` method |

---

## 10. Future Extensions

### 10.1 TODO: Delegation

```
delegate : Permission × Scope → Permission
delegate(π, s) = π @ s
```

Allow functions to delegate subset of permissions to callees.

### 10.2 TODO: Composite Permissions

```
composite ::= π₁ ∧ π₂    (both required)
            | π₁ ∨ π₂    (either sufficient)
            | ¬π          (negation)
```

### 10.3 TODO: Policy Language

```
policy ::= allow π when condition
         | deny π when condition
         | ask π when condition
```

---

## References

1. Arden, O. et al. (2015). "Sharing Mobile Code Securely With Information Flow Control"
2. Miller, M.S. (2006). "Robust Composition: Towards a Unified Approach to Access Control"
3. Felt, A.P. et al. (2012). "Android Permissions: User Attention, Comprehension, and Behavior"
4. Roesner, F. et al. (2012). "User-Driven Access Control"
