<!--
SPDX-License-Identifier: MPL-2.0
SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# WokeLang — handoff prompt for the next Claude

Paste the block below into a fresh Claude Code session working on
`hyperpolymath/wokelang`. (State as of 2026-06-19 — see `AFFIRMATION.adoc`.)

---

You are continuing work on **WokeLang**, a consent-driven, human-centred
programming language. Primary implementation is **Rust** (`src/`), with an
**OCaml** reference core (`core/`) and formal proofs in **Lean/Coq**
(`docs/proofs/verification/`) and **Idris 2** (`src/abi/`). Match the
interpreter (`src/interpreter/mod.rs`) as the reference semantics.

**Read first, in order:**
1. `AFFIRMATION.adoc` — the current MUST / INTEND / WISH standing (timestamped).
2. `.machine_readable/6a2/STATE.a2ml` — project state checkpoint.
3. `docs/proofs/verification/AUDIT.md` — proof state (Lean / Coq / Idris).
4. `PROOF-NEEDS.md`, `TEST-NEEDS.md`, `TOOLCHAIN-WISHLIST.md` — needs and wishes.
   (Note: `TOOLCHAIN-WISHLIST.md` is **stale** — LSP, the DAP debugger, and the
   WASM backend already exist; and it says 85% complete while `STATE.a2ml` says
   35%. Reconciling these is itself an open task.)

**Where things stand (2026-06-19):**
- **Proofs.** Lean + Coq at parity (expression-core type safety + arrays +
  statement typing) and an Idris consent calculus (typing with a handler
  context + small-step with an audit log + `progress`). CI-gated
  (`lean-proofs.yml`, `coq-proofs.yml`), `sorry`/axiom-free.
- **Bytecode VM** (`src/vm/`). Now runs the core language: Result types,
  records, indexing, control flow, **consent enforcement under `#care`**
  (deny-by-default), and **closures with upvalue capture**. 188 lib tests green.
  It went from crashing on most programs to running the core language this
  session (PRs #92–#94).

**Best next steps (near-horizon, mostly independent — pick one):**
- *VM → real compilation target:*
  - **Interpreter↔VM parity harness:** run each `conformance/*.woke` and
    `examples/*.woke` through both the interpreter and `vm::run_vm`, assert
    equal results, CI-gate it. (Highest-value correctness mechanism.)
  - **`.wbc` bytecode serialization:** `woke compile -o x.wbc` cannot write a
    loadable file yet (`src/main.rs` says "not yet implemented"); add serde
    round-trip so `woke run-vm x.wbc` loads it.
  - **Consent grant-sources:** seed the VM's `granted` set (in `src/vm/machine.rs`)
    from `superpower` declarations so `#care` programs can actually grant
    capabilities (currently deny-by-default).
  - **Worker statements on the VM** (the 5 concurrency forms — needs a VM
    channel/scheduler model).
  - **By-reference + multi-level closure capture** (current capture is by-value,
    single-level).
- *Proofs:* **float arithmetic** variants; **open-term expression preservation**
  (the prerequisite for statement *dynamic* safety); decide the **eval ↔ spec
  correspondence** question (PROOF-NEEDS #2) with the maintainer.
- *Docs:* **reconcile** `README.adoc` / `EXPLAINME.adoc` / `TOOLCHAIN-WISHLIST.md`
  to reality and fix the 35%-vs-85% completion contradiction.

**Conventions & CI gates:**
- Develop on the branch you are told to; push and open a **draft PR**.
- Gates include **Build Check** (`cargo fmt --check` + `cargo clippy --lib --bins
  -- -D warnings`), **Build + E2E (Rust + OCaml)**, **lean-proofs**, **coq-proofs**.
  **Run `cargo fmt` + `cargo clippy --lib --bins -- -D warnings` locally before
  pushing** — Build Check gates on both, and that has bitten past sessions.
- Language policy (`.claude/CLAUDE.md`): Rust / OCaml / Lean / Coq / Idris as
  present; no Go / Python / TypeScript; `Containerfile`, not `Dockerfile`.
- Keep proofs `sorry`/axiom-free; pin each headline theorem the way `AUDIT.md`
  describes.

Tell me which item to take, or propose one and go.

---
