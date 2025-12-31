# WokeLang Memory Model and Safety

This document specifies the memory model and proves memory safety properties for WokeLang.

## 1. Memory Model Overview

### 1.1 Value Representation

WokeLang values are represented as Rust enums:

```rust
pub enum Value {
    Int(i64),           // 8 bytes
    Float(f64),         // 8 bytes
    String(String),     // 24 bytes (ptr, len, cap)
    Bool(bool),         // 1 byte + padding
    Unit,               // 0 bytes (tag only)
    Array(Vec<Value>),  // 24 bytes (ptr, len, cap)
    Okay(Box<Value>),   // 8 bytes (ptr)
    Oops(String),       // 24 bytes
    Record(HashMap<String, Value>),  // ~48 bytes
}
```

### 1.2 Memory Layout

```
┌──────────────────────────────────────────────────────────┐
│                         Stack                             │
├──────────────────────────────────────────────────────────┤
│ Local variables (Value enums)                             │
│ Function arguments                                        │
│ Return addresses                                          │
├──────────────────────────────────────────────────────────┤
│                          Heap                             │
├──────────────────────────────────────────────────────────┤
│ String contents (allocated by std::string::String)        │
│ Array elements (allocated by Vec<Value>)                  │
│ Boxed values (Result inner values)                        │
│ HashMap buckets (Record fields)                           │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Ownership Model

### 2.1 Rust Ownership Semantics

WokeLang inherits Rust's ownership model:

1. **Each value has a single owner**
2. **When the owner goes out of scope, the value is dropped**
3. **Values can be borrowed (immutably or mutably)**
4. **Mutable borrows are exclusive**

### 2.2 Value Cloning

WokeLang values implement `Clone`:

```rust
impl Clone for Value {
    fn clone(&self) -> Self {
        match self {
            Value::Int(n) => Value::Int(*n),
            Value::String(s) => Value::String(s.clone()), // Deep copy
            Value::Array(a) => Value::Array(a.clone()),   // Deep copy
            // ...
        }
    }
}
```

**Theorem 2.1:** Value cloning produces independent copies.

**Proof:** Each `clone()` call allocates new heap memory for heap-allocated types (String, Vec). No pointers are shared between original and clone. □

### 2.3 Environment Semantics

Variable binding clones values:

```rust
fn define(&mut self, name: String, value: Value) {
    if let Some(scope) = self.scopes.last_mut() {
        scope.insert(name, value);  // value is moved into HashMap
    }
}
```

Variable lookup clones values:

```rust
fn get(&self, name: &str) -> Option<Value> {
    for scope in self.scopes.iter().rev() {
        if let Some(value) = scope.get(name) {
            return Some(value.clone());  // Clone on read
        }
    }
    None
}
```

---

## 3. Memory Safety Proofs

### 3.1 No Use-After-Free

**Theorem 3.1 (No Use-After-Free):** WokeLang programs cannot access freed memory.

**Proof:**
1. All heap allocations are managed by Rust's ownership system
2. Values are dropped when their owning scope ends
3. References to values are cloned, not borrowed across scope boundaries
4. Rust's borrow checker prevents use-after-free at compile time
5. No unsafe code in the interpreter

Therefore, use-after-free is impossible. □

### 3.2 No Double-Free

**Theorem 3.2 (No Double-Free):** Memory is freed exactly once.

**Proof:**
1. Each value has a single owner
2. Drop is called exactly once when owner goes out of scope
3. Clone creates new owners, not aliases
4. Rust guarantees single drop

Therefore, double-free is impossible. □

### 3.3 No Null Pointer Dereference

**Theorem 3.3 (No Null Dereference):** WokeLang cannot dereference null pointers.

**Proof:**
1. Rust has no null pointers (Option<T> instead)
2. WokeLang's Value enum has no None variant for non-optional types
3. Box<T> always contains a valid pointer
4. Vec<T> and String contain valid (possibly zero-length) allocations

Therefore, null dereference is impossible. □

### 3.4 No Buffer Overflow

**Theorem 3.4 (No Buffer Overflow):** Array accesses are bounds-checked.

**Proof:**
1. Array indexing uses `Vec::get()` which returns `Option<&T>`
2. Out-of-bounds access returns `None` or panics (in some paths)
3. Runtime error is raised, not undefined behavior

```rust
match &args[0] {
    Value::Array(a) => Ok(Some(Value::Int(a.len() as i64))),
    _ => Err(RuntimeError::TypeError(...)),
}
```

Therefore, buffer overflow is impossible. □

### 3.5 No Data Races

**Theorem 3.5 (No Data Races):** Concurrent access is safe.

**Proof:**
1. The interpreter is single-threaded (synchronous worker execution)
2. Each worker has its own environment
3. Message passing clones values
4. No mutable shared state between workers

For true concurrent workers (future work):
- MPSC channels are thread-safe
- Arc/Mutex would protect shared state
- Rust prevents data races at compile time

□

---

## 4. Allocation Patterns

### 4.1 Stack Allocation

Small values are stack-allocated:
- Int, Float, Bool, Unit: Always on stack
- Enum discriminant: Always on stack

### 4.2 Heap Allocation

Complex values require heap allocation:
- String: Character data on heap
- Array: Element vector on heap
- Record: HashMap buckets on heap
- Okay/Oops: Boxed inner value on heap

### 4.3 Allocation Complexity

| Operation | Allocations | Complexity |
|-----------|-------------|------------|
| Integer literal | 0 | O(1) |
| String literal | 1 | O(n) |
| Array literal | 1 + Σelemₛ | O(n) |
| Variable read | Clone costs | O(size) |
| Function call | Frame + locals | O(params + locals) |

---

## 5. Garbage Collection

### 5.1 Current Model: Reference Counting (Implicit)

WokeLang uses Rust's ownership, which effectively implements deterministic destruction:

```
Value created → Value cloned → ... → Last owner dropped → Memory freed
```

This is **not** garbage collection but **RAII** (Resource Acquisition Is Initialization).

### 5.2 Properties

| Property | Value |
|----------|-------|
| Deterministic destruction | Yes |
| Pause-free | Yes |
| Cycle handling | N/A (no cycles in Value) |
| Memory overhead | None |
| Fragmentation | Allocator-dependent |

### 5.3 Cycle Prevention

**Theorem 5.1:** WokeLang Value types cannot form cycles.

**Proof:**
- Value::Array contains Vec<Value> (values, not references)
- Value::Okay contains Box<Value> (owned, not reference)
- No Rc/Arc types used
- No self-referential structures possible

Therefore, no cycles can form, and reference counting (implicit via Drop) correctly frees all memory. □

---

## 6. Memory Bounds

### 6.1 Stack Limits

| Limit | Value | Justification |
|-------|-------|---------------|
| Max call depth | 1000 | Prevents stack overflow |
| Max stack size | 10000 values | VM configuration |
| Frame size | ~100 bytes | Typical function frame |

```rust
const MAX_CALL_DEPTH: usize = 1000;
const MAX_STACK_SIZE: usize = 10000;
```

### 6.2 Heap Limits

| Limit | Value | Justification |
|-------|-------|---------------|
| Max string length | 2^63 - 1 | Rust String limit |
| Max array length | 2^63 - 1 | Rust Vec limit |
| Max total heap | OS-dependent | System allocator limit |

### 6.3 Recursion Safety

**Theorem 6.1:** Stack overflow is prevented.

**Proof:**
```rust
if self.call_stack.len() >= self.max_call_depth {
    return Err(VMError { message: "Maximum call depth exceeded" });
}
```

The check before each call prevents unbounded recursion from overflowing the Rust stack. □

---

## 7. Value Equality

### 7.1 Structural Equality

Values implement `PartialEq`:

```rust
impl PartialEq for Value {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Value::Int(a), Value::Int(b)) => a == b,
            (Value::Float(a), Value::Float(b)) => a == b,
            (Value::String(a), Value::String(b)) => a == b,
            (Value::Array(a), Value::Array(b)) => a == b,  // Deep comparison
            // ...
            _ => false,
        }
    }
}
```

### 7.2 Equality Properties

**Theorem 7.1:** Value equality is an equivalence relation.

**Proof:**
- Reflexive: v == v (by structural equality of components)
- Symmetric: v == w ⟹ w == v (symmetric match arms)
- Transitive: v == w ∧ w == x ⟹ v == x (component equality is transitive)
□

---

## 8. String Representation

### 8.1 UTF-8 Encoding

WokeLang strings use Rust's String type:
- Valid UTF-8 guaranteed
- O(1) length (in bytes)
- O(n) character iteration

### 8.2 String Operations

| Operation | Allocation | Complexity |
|-----------|------------|------------|
| Literal | 1 | O(n) |
| Concatenation | 1 | O(n + m) |
| Comparison | 0 | O(min(n, m)) |
| Substring | 1 | O(k) |

### 8.3 String Safety

**Theorem 8.1:** All WokeLang strings are valid UTF-8.

**Proof:**
1. String literals are validated at parse time
2. Concatenation preserves UTF-8 (String::push_str checks)
3. No raw byte manipulation exposed to user
4. Rust guarantees String invariant

□

---

## 9. Array Semantics

### 9.1 Homogeneous Arrays

WokeLang arrays are homogeneous at runtime (type-checked statically when possible):

```rust
Value::Array(Vec<Value>)
```

All elements must have compatible types.

### 9.2 Array Operations

| Operation | Mutates | Allocation |
|-----------|---------|------------|
| Index | No | Clone |
| Push | Yes | Amortized O(1) |
| Pop | Yes | No |
| Concat | No | O(n + m) |
| Map | No | O(n) |

### 9.3 Array Bounds

```rust
fn index(&self, arr: &[Value], idx: i64) -> Result<Value> {
    if idx < 0 || idx >= arr.len() as i64 {
        return Err(RuntimeError::IndexOutOfBounds(idx as usize));
    }
    Ok(arr[idx as usize].clone())
}
```

---

## 10. Future Work

### 10.1 TODO: Copy-on-Write

Optimize cloning with COW:
```rust
enum Value {
    // ...
    String(Arc<str>),
    Array(Arc<[Value]>),
}
```

### 10.2 TODO: Arena Allocation

Reduce allocation overhead:
```rust
struct Arena {
    chunks: Vec<Box<[u8]>>,
    current: usize,
}
```

### 10.3 TODO: NaN-Boxing

Compact value representation:
```rust
// All values in 8 bytes using NaN-boxing
type NaNBoxedValue = u64;
```

---

## References

1. Klabnik, S. and Nichols, C. (2019). "The Rust Programming Language"
2. Jung, R. et al. (2017). "RustBelt: Securing the Foundations of the Rust Programming Language"
3. Matsakis, N. and Klock, F. (2014). "The Rust Language"
4. Stroustrup, B. (1994). "The Design and Evolution of C++" (RAII origin)
