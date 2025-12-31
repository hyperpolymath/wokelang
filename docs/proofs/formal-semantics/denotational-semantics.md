# WokeLang Denotational Semantics

This document provides the mathematical denotational semantics for WokeLang, giving precise meaning to programs as mathematical objects.

## 1. Semantic Domains

### 1.1 Base Domains

```
ℤ₆₄ = {-2⁶³, ..., 2⁶³-1}           (64-bit signed integers)
ℝ₆₄ = IEEE 754 double precision    (64-bit floats)
𝔹 = {true, false}                   (booleans)
𝕊 = Σ*                              (strings over UTF-8 alphabet Σ)
𝟙 = {unit}                          (unit type)
```

### 1.2 Lifted Domains

For any domain D, we define the lifted domain D⊥ = D ∪ {⊥} where ⊥ represents non-termination or error.

### 1.3 Value Domain

The domain of WokeLang values is defined recursively:

```
𝕍 = ℤ₆₄ + ℝ₆₄ + 𝕊 + 𝔹 + 𝟙 + 𝕍* + (𝕍 + 𝕊) + (𝕍 →ᶜ 𝕍⊥)
```

Where:
- `𝕍*` = finite sequences (arrays)
- `𝕍 + 𝕊` = Result type (Okay(v) | Oops(s))
- `𝕍 →ᶜ 𝕍⊥` = continuous functions (closures)

### 1.4 Environment Domain

```
Env = Ident → 𝕍⊥
```

### 1.5 Store Domain (for mutable state)

```
Store = Loc → 𝕍⊥
```

### 1.6 Continuation Domain

```
Cont = 𝕍 → Ans
Ans = 𝕍⊥
```

### 1.7 Consent Domain

```
Consent = ℘(Permission)
Permission = 𝕊
```

---

## 2. Semantic Functions

### 2.1 Expression Semantics

The semantic function for expressions:

```
ℰ⟦·⟧ : Expr → Env → Consent → 𝕍⊥
```

#### Literals

```
ℰ⟦n⟧ρ C = n                              where n ∈ ℤ₆₄
ℰ⟦f⟧ρ C = f                              where f ∈ ℝ₆₄
ℰ⟦s⟧ρ C = s                              where s ∈ 𝕊
ℰ⟦true⟧ρ C = true
ℰ⟦false⟧ρ C = false
ℰ⟦unit⟧ρ C = unit
```

#### Variables

```
ℰ⟦x⟧ρ C = ρ(x)
```

#### Binary Operations

```
ℰ⟦e₁ + e₂⟧ρ C =
    let v₁ = ℰ⟦e₁⟧ρ C in
    let v₂ = ℰ⟦e₂⟧ρ C in
    case (v₁, v₂) of
        (n₁ : ℤ, n₂ : ℤ) → n₁ + n₂
        (f₁ : ℝ, f₂ : ℝ) → f₁ + f₂
        (n : ℤ, f : ℝ) → (n : ℝ) + f
        (f : ℝ, n : ℤ) → f + (n : ℝ)
        (s₁ : 𝕊, s₂ : 𝕊) → s₁ ++ s₂
        _ → ⊥

ℰ⟦e₁ - e₂⟧ρ C =
    let v₁ = ℰ⟦e₁⟧ρ C in
    let v₂ = ℰ⟦e₂⟧ρ C in
    case (v₁, v₂) of
        (n₁ : ℤ, n₂ : ℤ) → n₁ - n₂
        (f₁ : ℝ, f₂ : ℝ) → f₁ - f₂
        (n : ℤ, f : ℝ) → (n : ℝ) - f
        (f : ℝ, n : ℤ) → f - (n : ℝ)
        _ → ⊥

ℰ⟦e₁ * e₂⟧ρ C =
    let v₁ = ℰ⟦e₁⟧ρ C in
    let v₂ = ℰ⟦e₂⟧ρ C in
    case (v₁, v₂) of
        (n₁ : ℤ, n₂ : ℤ) → n₁ × n₂
        (f₁ : ℝ, f₂ : ℝ) → f₁ × f₂
        (n : ℤ, f : ℝ) → (n : ℝ) × f
        (f : ℝ, n : ℤ) → f × (n : ℝ)
        _ → ⊥

ℰ⟦e₁ / e₂⟧ρ C =
    let v₁ = ℰ⟦e₁⟧ρ C in
    let v₂ = ℰ⟦e₂⟧ρ C in
    case (v₁, v₂) of
        (n₁ : ℤ, n₂ : ℤ) → if n₂ = 0 then ⊥ else n₁ ÷ n₂
        (f₁ : ℝ, f₂ : ℝ) → if f₂ = 0.0 then ⊥ else f₁ / f₂
        _ → ⊥

ℰ⟦e₁ % e₂⟧ρ C =
    let v₁ = ℰ⟦e₁⟧ρ C in
    let v₂ = ℰ⟦e₂⟧ρ C in
    case (v₁, v₂) of
        (n₁ : ℤ, n₂ : ℤ) → if n₂ = 0 then ⊥ else n₁ mod n₂
        _ → ⊥
```

#### Comparison Operations

```
ℰ⟦e₁ == e₂⟧ρ C =
    let v₁ = ℰ⟦e₁⟧ρ C in
    let v₂ = ℰ⟦e₂⟧ρ C in
    v₁ = v₂

ℰ⟦e₁ != e₂⟧ρ C = ¬(ℰ⟦e₁ == e₂⟧ρ C)

ℰ⟦e₁ < e₂⟧ρ C =
    let v₁ = ℰ⟦e₁⟧ρ C in
    let v₂ = ℰ⟦e₂⟧ρ C in
    case (v₁, v₂) of
        (n₁ : ℤ, n₂ : ℤ) → n₁ < n₂
        (f₁ : ℝ, f₂ : ℝ) → f₁ < f₂
        (s₁ : 𝕊, s₂ : 𝕊) → s₁ <ₗₑₓ s₂
        _ → ⊥
```

#### Logical Operations

```
ℰ⟦e₁ and e₂⟧ρ C =
    let v₁ = ℰ⟦e₁⟧ρ C in
    if truthy(v₁) then
        truthy(ℰ⟦e₂⟧ρ C)
    else
        false

ℰ⟦e₁ or e₂⟧ρ C =
    let v₁ = ℰ⟦e₁⟧ρ C in
    if truthy(v₁) then
        true
    else
        truthy(ℰ⟦e₂⟧ρ C)
```

Where `truthy` is defined as:
```
truthy(false) = false
truthy(0) = false
truthy(0.0) = false
truthy("") = false
truthy(unit) = false
truthy([]) = false
truthy(Oops(_)) = false
truthy(_) = true
```

#### Unary Operations

```
ℰ⟦-e⟧ρ C =
    let v = ℰ⟦e⟧ρ C in
    case v of
        n : ℤ → -n
        f : ℝ → -f
        _ → ⊥

ℰ⟦not e⟧ρ C = ¬truthy(ℰ⟦e⟧ρ C)
```

#### Function Calls

```
ℰ⟦f(e₁,...,eₙ)⟧ρ C =
    let v₁ = ℰ⟦e₁⟧ρ C in
    ...
    let vₙ = ℰ⟦eₙ⟧ρ C in
    ℱ⟦f⟧(v₁,...,vₙ) C
```

#### Arrays

```
ℰ⟦[e₁,...,eₙ]⟧ρ C =
    let v₁ = ℰ⟦e₁⟧ρ C in
    ...
    let vₙ = ℰ⟦eₙ⟧ρ C in
    [v₁,...,vₙ]
```

#### Array Indexing

```
ℰ⟦e₁[e₂]⟧ρ C =
    let arr = ℰ⟦e₁⟧ρ C in
    let idx = ℰ⟦e₂⟧ρ C in
    case (arr, idx) of
        ([v₀,...,vₖ], n : ℤ) → if 0 ≤ n ≤ k then vₙ else ⊥
        _ → ⊥
```

#### Result Types

```
ℰ⟦Okay(e)⟧ρ C = inl(ℰ⟦e⟧ρ C)
ℰ⟦Oops(e)⟧ρ C = inr(ℰ⟦e⟧ρ C)

ℰ⟦unwrap e⟧ρ C =
    case ℰ⟦e⟧ρ C of
        inl(v) → v
        inr(s) → ⊥
```

#### Unit Measurement

```
ℰ⟦e measured in u⟧ρ C = ℰ⟦e⟧ρ C
```

Note: Units are currently annotations only. See Section 6 for dimensional analysis extension.

---

### 2.2 Statement Semantics

Statement semantics use a continuation-passing style:

```
𝒮⟦·⟧ : Stmt → Env → Consent → Cont → (Env × Consent × Ans)
```

#### Variable Declaration

```
𝒮⟦remember x = e⟧ρ C κ =
    let v = ℰ⟦e⟧ρ C in
    case v of
        ⊥ → (ρ, C, ⊥)
        v → (ρ[x ↦ v], C, κ(unit))
```

#### Assignment

```
𝒮⟦x = e⟧ρ C κ =
    let v = ℰ⟦e⟧ρ C in
    case v of
        ⊥ → (ρ, C, ⊥)
        v → if x ∈ dom(ρ) then (ρ[x ↦ v], C, κ(unit))
            else (ρ, C, ⊥)
```

#### Return

```
𝒮⟦give back e⟧ρ C κ =
    let v = ℰ⟦e⟧ρ C in
    (ρ, C, v)
```

Note: Return ignores the continuation κ.

#### Conditional

```
𝒮⟦when e {s₁*} otherwise {s₂*}⟧ρ C κ =
    let b = ℰ⟦e⟧ρ C in
    if truthy(b) then
        𝒮*⟦s₁*⟧ρ C κ
    else
        𝒮*⟦s₂*⟧ρ C κ
```

#### Loop

```
𝒮⟦repeat e times {s*}⟧ρ C κ =
    let n = ℰ⟦e⟧ρ C in
    case n of
        n : ℤ → loop(n, ρ, C, κ)
        _ → (ρ, C, ⊥)

where loop(n, ρ, C, κ) =
    if n ≤ 0 then (ρ, C, κ(unit))
    else let (ρ', C', r) = 𝒮*⟦s*⟧ρ C (λ_. unit) in
         case r of
             ⊥ → (ρ', C', ⊥)
             _ → loop(n-1, ρ', C', κ)
```

#### Attempt Block

```
𝒮⟦attempt safely {s*} or reassure msg⟧ρ C κ =
    let (ρ', C', r) = 𝒮*⟦s*⟧ρ C κ in
    case r of
        ⊥ → (ρ, C, κ(unit))    -- Error recovery
        v → (ρ', C', v)         -- Success
```

#### Consent Block

```
𝒮⟦only if okay perm {s*}⟧ρ C κ =
    if perm ∈ C then
        𝒮*⟦s*⟧ρ C κ
    else
        (ρ, C, κ(unit))    -- Silently skip if no consent
```

#### Pattern Matching

```
𝒮⟦decide based on e {p₁ → {s₁*}; ...; pₙ → {sₙ*}}⟧ρ C κ =
    let v = ℰ⟦e⟧ρ C in
    case firstMatch(v, [(p₁, s₁*), ..., (pₙ, sₙ*)], ρ) of
        Some(bindings, s*) → 𝒮*⟦s*⟧(ρ ⊕ bindings) C κ
        None → (ρ, C, κ(unit))
```

#### Statement Sequence

```
𝒮*⟦ε⟧ρ C κ = (ρ, C, κ(unit))

𝒮*⟦s; s*⟧ρ C κ =
    let (ρ', C', r) = 𝒮⟦s⟧ρ C (λ_. unit) in
    case r of
        ⊥ → (ρ', C', ⊥)
        _ → if isReturn(r) then (ρ', C', r)
            else 𝒮*⟦s*⟧ρ' C' κ
```

---

### 2.3 Function Semantics

```
ℱ⟦·⟧ : FunctionDef → Env
ℱ⟦to f(x₁,...,xₙ) { body }⟧ =
    λ(v₁,...,vₙ). λC.
        let ρ = [x₁ ↦ v₁, ..., xₙ ↦ vₙ] in
        let (_, _, r) = 𝒮*⟦body⟧ρ C (λv. v) in
        r
```

---

### 2.4 Program Semantics

```
𝒫⟦·⟧ : Program → Consent → 𝕍⊥

𝒫⟦program⟧C =
    let Φ = collectFunctions(program) in
    let C' = processGratitude(program, C) in
    if "main" ∈ dom(Φ) then
        ℱ⟦Φ("main")⟧() C'
    else
        unit
```

---

## 3. Semantic Properties

### 3.1 Compositionality

**Theorem 3.1:** WokeLang semantics are compositional.

For any expression context E[·]:
```
ℰ⟦E[e]⟧ρ C = ℰ⟦E⟧(ℰ⟦e⟧ρ C) ρ C
```

### 3.2 Monotonicity

**Theorem 3.2:** All semantic functions are monotonic with respect to the information ordering ⊑ on domains.

```
If ρ₁ ⊑ ρ₂ then ℰ⟦e⟧ρ₁ C ⊑ ℰ⟦e⟧ρ₂ C
```

### 3.3 Continuity

**Theorem 3.3:** All semantic functions are continuous (preserve least upper bounds of directed sets).

This ensures that fixed-point semantics for recursion are well-defined.

### 3.4 Adequacy

**Theorem 3.4 (Computational Adequacy):** The denotational semantics agrees with operational semantics.

```
ℰ⟦e⟧ρ C = v  ⟺  ⟨e, ρ, Φ, C⟩ ⇓ v
```

---

## 4. Domain Equations

### 4.1 Solving Recursive Domain Equations

The value domain 𝕍 satisfies:

```
𝕍 ≅ ℤ₆₄ + ℝ₆₄ + 𝕊 + 𝔹 + 𝟙 + 𝕍* + (𝕍 + 𝕊) + (𝕍 →ᶜ 𝕍⊥)
```

This is solved using standard techniques:
1. Initial algebra construction
2. Limit of finite approximations
3. Category-theoretic solution in CPO

### 4.2 Fixed Points for Recursion

For recursive functions, we use the least fixed point:

```
ℱ⟦to f(x) { ...f(e)... }⟧ = fix(λφ. λv. λC.
    let ρ = [x ↦ v, f ↦ φ] in
    𝒮*⟦body⟧ρ C (λv. v))
```

Where `fix` is the least fixed point operator on continuous functions.

---

## 5. Algebraic Laws

### 5.1 Expression Equivalences

```
-- Commutativity
e₁ + e₂ ≡ e₂ + e₁                    (for numeric e₁, e₂)
e₁ * e₂ ≡ e₂ * e₁                    (for numeric e₁, e₂)
e₁ and e₂ ≡ e₂ and e₁
e₁ or e₂ ≡ e₂ or e₁

-- Associativity
(e₁ + e₂) + e₃ ≡ e₁ + (e₂ + e₃)      (modulo overflow)
(e₁ * e₂) * e₃ ≡ e₁ * (e₂ * e₃)      (modulo overflow)

-- Identity
e + 0 ≡ e
e * 1 ≡ e
e and true ≡ e
e or false ≡ e

-- Annihilation
e * 0 ≡ 0                             (if e terminates)
e and false ≡ false                   (short-circuit)
e or true ≡ true                      (short-circuit)

-- Distributivity
e₁ * (e₂ + e₃) ≡ (e₁ * e₂) + (e₁ * e₃)

-- Result type laws
unwrap(Okay(e)) ≡ e
isOkay(Okay(e)) ≡ true
isOkay(Oops(e)) ≡ false
```

### 5.2 Statement Equivalences

```
-- Idempotent assignment
x = e; x = e ≡ x = e

-- Dead code elimination
give back e; s ≡ give back e

-- Consent block identity
only if okay p { s } ≡ s             (when p is granted)
only if okay p { s } ≡ skip          (when p is denied)

-- Loop unrolling
repeat 0 times { s } ≡ skip
repeat 1 times { s } ≡ s
repeat (n+1) times { s } ≡ s; repeat n times { s }
```

---

## 6. Extensions

### 6.1 Dimensional Analysis (Future Work)

**TODO:** Extend value domain with units:

```
𝕍ᵤ = (ℤ₆₄ × Unit) + (ℝ₆₄ × Unit) + ...

Unit = m^α · kg^β · s^γ · A^δ · K^ε · mol^ζ · cd^η
     where α,β,γ,δ,ε,ζ,η ∈ ℤ
```

Semantic rules would then include unit checking:

```
ℰ⟦e₁ + e₂⟧ρ C =
    let (v₁, u₁) = ℰ⟦e₁⟧ρ C in
    let (v₂, u₂) = ℰ⟦e₂⟧ρ C in
    if u₁ = u₂ then (v₁ + v₂, u₁) else ⊥
```

### 6.2 Effect Semantics (Future Work)

**TODO:** Model side effects using monads or algebraic effects:

```
𝕍ₑ = T(𝕍)
where T = State × IO × Consent × Error
```

---

## References

1. Scott, D.S. (1970). "Outline of a Mathematical Theory of Computation"
2. Stoy, J.E. (1977). "Denotational Semantics: The Scott-Strachey Approach"
3. Winskel, G. (1993). "The Formal Semantics of Programming Languages"
4. Schmidt, D.A. (1986). "Denotational Semantics: A Methodology for Language Development"
