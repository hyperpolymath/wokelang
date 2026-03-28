<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

# WokeLang — System Specifications

WokeLang is an interpreted language with a Rust interpreter and OCaml parser,
featuring consent-based programming and social-justice-informed semantics.

## Memory Model

WokeLang uses a hybrid memory model suited to its interpreter architecture:

- **Single-thread environments**: Values are stored in environments using
  `Rc<RefCell<T>>` (reference-counted, interior-mutable cells). This avoids the
  overhead of atomic operations when concurrency is not needed.
- **Worker environments**: When workers are spawned, environments switch to
  `Arc<Mutex<T>>` for thread-safe shared access. Each worker receives an isolated
  copy of its captured environment at spawn time.
- **Value semantics**: Primitive values (numbers, booleans, strings) are cloned on
  assignment. Compound values (lists, maps) use reference counting with
  copy-on-write where applicable.
- **No garbage collector**: Memory is reclaimed through reference counting. Cycle
  detection is not currently implemented; cyclic structures will leak.
- **Stack frames**: Function calls push frames onto an explicit call stack in the
  interpreter. Each frame holds local bindings as a HashMap.
- **Environment chains**: Lexical scoping is implemented via linked environment
  chains. Each scope holds a reference to its parent scope.

## Concurrency Model

WokeLang provides several concurrency primitives:

- **Workers**: Spawned via dedicated syntax, workers run on OS threads
  (`std::thread::spawn`). Each worker receives an isolated copy of its environment,
  preventing shared mutable state between workers.
- **Channels**: Go-style communication channels built on Rust's `mpsc`
  (multi-producer, single-consumer). Workers communicate by sending and receiving
  values through named channels.
- **Side quests**: Lightweight background tasks that run concurrently with the main
  program. Side quests have lower priority than the main thread and report results
  asynchronously.
- **Superpowers**: Elevated execution contexts that can bypass normal consent checks
  for system-level operations. Superpowers run in isolated sandboxes with explicit
  capability grants.
- **No shared memory**: Workers cannot access each other's environments. All
  inter-worker communication goes through channels, preventing data races by design.
- **Join semantics**: The main thread can wait for workers to complete and collect
  their return values.

## Effect System

WokeLang's effect system is built around the consent model:

- **Consent system**: The primary effect-management mechanism. Operations that
  affect state, perform IO, or access sensitive resources require explicit consent
  through `only if okay` gates.
- **`only if okay` gates**: Before performing a side effect, the runtime checks
  whether consent has been granted for that category of effect. Unconsented effects
  are blocked at runtime.
- **Effect categories**: Effects are classified into categories (IO, network, file
  system, environment access). Consent is granted per-category.
- **Consent propagation**: When a function calls another function, consent context
  propagates through the call chain. Inner functions cannot escalate beyond the
  consent granted to their callers.
- **Monotonic consent**: Consent is monotonic within a session — once granted,
  it only grows and is never revoked during execution. New consent categories
  can be added but existing grants persist until session end.
- **Audit trail**: All consent checks are logged, providing a runtime trace of
  which effects were attempted and whether they were permitted.

## Module System

WokeLang uses a straightforward import/export model:

- **`use` imports**: Modules are imported with the `use` keyword. Specific bindings
  can be selected and optionally renamed with the `renamed` keyword:
  `use math (sqrt, pow renamed power)`.
- **`share` exports**: Public bindings are explicitly exported with the `share`
  keyword. Only shared bindings are visible to importing modules.
- **File-based modules**: Each source file is a module. The module name is derived
  from the file path relative to the project root.
- **Namespace isolation**: Imported names do not pollute the global scope. They are
  scoped to the importing module unless explicitly re-shared.
- **Circular dependency detection**: The module loader detects circular imports and
  raises an error at load time rather than entering infinite recursion.
- **No package manager yet**: Dependencies are managed manually via file paths.
  A package ecosystem is planned for future releases.
