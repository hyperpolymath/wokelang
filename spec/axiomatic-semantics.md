# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

# WokeLang Axiomatic Semantics: Consent Preconditions

**Version:** 1.0.0
**Date:** 2026-03-14

---

## 1. Overview

WokeLang's axiomatic semantics extend Hoare logic with *consent preconditions*
— formal requirements that certain operations may only proceed if explicit
user consent has been obtained. This ensures that WokeLang programs cannot
perform sensitive operations silently.

### 1.1 Consent Hoare Triple

```
{P, C} S {Q, C'}

where C ⊆ ConsentSet is the set of active consents
```

---

## 2. Consent Axioms

### 2.1 Consent Gate

```
    prompt ∉ C     user grants consent
    ────────────────────────────────────────────────────────  [Consent-Grant]
    {P, C} only if okay "prompt" { S } {Q, C ∪ {prompt}}

    prompt ∉ C     user denies consent
    ────────────────────────────────────────────────────  [Consent-Deny]
    {P, C} only if okay "prompt" { S } {P, C}
    (body S is not executed; program continues)
```

### 2.2 Consent Propagation

```
    prompt ∈ C     (consent already granted)
    ──────────────────────────────────────────────────  [Consent-Cached]
    {P, C} only if okay "prompt" { S } {Q, C}
    (body executes without re-prompting)
```

### 2.3 Consent Requirement

Operations that access external resources require consent:

```
    requires_consent(op) = true     "access" ∉ C
    ──────────────────────────────────────────────────────  [Consent-Required]
    {P, C} op {⊥}     (error: consent not obtained)
```

---

## 3. Gratitude Axioms

### 3.1 Attribution Preservation

```
    ──────────────────────────────────────────────────────────  [Grat-Preserve]
    {true, C} thanks to { entries } {gratitude_table updated, C}
    (gratitude declarations are pure metadata — no side effects)
```

### 3.2 Gratitude Completeness

**Axiom:** Every function using external code should have a corresponding
`thanks to` block. This is a convention, not enforced by the type system.

---

## 4. Worker Axioms

### 4.1 Worker Isolation

```
    ──────────────────────────────────────────────────────  [W-Isolate]
    {P, C} spawn worker W {Q ∧ ρ_W ∩ ρ_parent = ∅, C}
    (workers have their own isolated environment)
```

### 4.2 Channel Safety

```
    channel(ch) open     value : τ
    ────────────────────────────────────────  [W-Send]
    {channel_open(ch), C} send value to ch {message_queued, C}

    channel(ch) has message
    ────────────────────────────────────────  [W-Recv]
    {message_available(ch), C} receive from ch {value received, C}

    channel(ch) empty     (blocking semantics)
    ──────────────────────────────────────────────  [W-Recv-Block]
    {¬message_available(ch), C} receive from ch {blocks until message, C}
```

### 4.3 Worker Lifecycle

```
    W running
    ──────────────────────────────────  [W-Cancel]
    {worker_alive(W), C} cancel W {worker_cancelled(W), C}

    W running
    ──────────────────────────────────  [W-Await]
    {worker_alive(W), C} await W {worker_completed(W), C}
```

---

## 5. Error Handling Axioms

### 5.1 Attempt Block

```
    {P, C} S {Q, C}     (S succeeds)
    ──────────────────────────────────────────────────────────  [Err-Success]
    {P, C} attempt safely { S } or reassure msg {Q, C}

    {P, C} S {⊥}     (S fails)
    ──────────────────────────────────────────────────────────  [Err-Reassure]
    {P, C} attempt safely { S } or reassure msg {error handled, C}
    (msg displayed; execution continues)
```

### 5.2 Complain

```
    ──────────────────────────────────────────────  [Err-Complain]
    {true, C} complain msg {⊥}     (error raised)
```

---

## 6. Result Type Axioms

```
    ──────────────────────────────────────────  [Res-Okay]
    {true, C} Okay(v) {result = Ok(v), C}

    ──────────────────────────────────────────  [Res-Oops]
    {true, C} Oops(e) {result = Err(e), C}

    result = Ok(v)
    ──────────────────────────────────  [Res-Unwrap-Ok]
    {result = Ok(v), C} unwrap result {value = v, C}

    result = Err(e)
    ──────────────────────────────────────────  [Res-Unwrap-Err]
    {result = Err(e), C} unwrap result {⊥}
```

---

## 7. Pragma Axioms

```
    ──────────────────────────────────────────────────────  [Pragma-Care]
    {true, C} #care on {extra_validation = true, C}
    (enables additional safety checks)

    ──────────────────────────────────────────────────────  [Pragma-Strict]
    {true, C} #strict on {warnings_are_errors = true, C}
```

---

## 8. Key Theorems

### 8.1 Consent Safety

**Theorem:** No operation requiring consent can execute without explicit
consent in the consent set C. The consent gate is the only way to add
elements to C.

### 8.2 Worker Isolation

**Theorem:** Workers cannot access the parent environment's mutable state.
Communication is exclusively through channels (message passing).

### 8.3 Gentle Error Handling

**Theorem:** An `attempt safely` block never causes program termination.
All errors within the block are caught and the reassurance message is
displayed.

### 8.4 Consent Monotonicity

**Theorem:** The consent set C only grows during execution (consents are
never revoked within a session): `{P, C} S {Q, C'} ⟹ C ⊆ C'`.
