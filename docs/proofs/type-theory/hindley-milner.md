# WokeLang Hindley-Milner Type Inference

This document formalizes the type inference algorithm used in WokeLang, based on the Hindley-Milner type system with extensions for Result types.

## 1. Type Language

### 1.1 Monotypes

```
τ ∈ Monotype ::= α                      (type variable)
               | Int | Float | String | Bool | Unit
               | [τ]                    (array type)
               | Maybe τ                (optional type)
               | Result[τ, τ]           (result type)
               | (τ₁,...,τₙ) → τ        (function type)
```

### 1.2 Type Schemes (Polytypes)

```
σ ∈ TypeScheme ::= τ                    (monotype)
                 | ∀α.σ                  (universal quantification)
```

### 1.3 Free Type Variables

```
FTV(α) = {α}
FTV(Int) = FTV(Float) = FTV(String) = FTV(Bool) = FTV(Unit) = ∅
FTV([τ]) = FTV(τ)
FTV(Maybe τ) = FTV(τ)
FTV(Result[τ₁, τ₂]) = FTV(τ₁) ∪ FTV(τ₂)
FTV((τ₁,...,τₙ) → τ) = FTV(τ₁) ∪ ... ∪ FTV(τₙ) ∪ FTV(τ)
FTV(∀α.σ) = FTV(σ) \ {α}
FTV(Γ) = ⋃{FTV(σ) | x:σ ∈ Γ}
```

---

## 2. Substitutions

### 2.1 Definition

A substitution S is a finite mapping from type variables to types:

```
S : TypeVar ⇀ Monotype
```

### 2.2 Application

```
S(α) = S(α) if α ∈ dom(S), else α
S(Int) = Int, etc.
S([τ]) = [S(τ)]
S(Maybe τ) = Maybe S(τ)
S(Result[τ₁, τ₂]) = Result[S(τ₁), S(τ₂)]
S((τ₁,...,τₙ) → τ) = (S(τ₁),...,S(τₙ)) → S(τ)
S(∀α.σ) = ∀α.S\{α}(σ)
S(Γ) = {x : S(σ) | x:σ ∈ Γ}
```

### 2.3 Composition

```
(S₁ ∘ S₂)(α) = S₁(S₂(α))
```

### 2.4 Identity

```
id = ∅ (empty substitution)
```

---

## 3. Unification

### 3.1 Most General Unifier (MGU)

The unification algorithm computes the most general unifier of two types.

**Definition:** S is a unifier of τ₁ and τ₂ if S(τ₁) = S(τ₂).

**Definition:** S is the MGU of τ₁ and τ₂ if:
1. S unifies τ₁ and τ₂
2. For any other unifier S', there exists S'' such that S' = S'' ∘ S

### 3.2 Unification Algorithm

```
unify(τ, τ) = id

unify(α, τ) =
    if α ∈ FTV(τ) and τ ≠ α then fail (occurs check)
    else [α ↦ τ]

unify(τ, α) = unify(α, τ)

unify(Int, Float) = [promote: Int → Float]  -- Widening
unify(Float, Int) = [promote: Int → Float]  -- Widening

unify([τ₁], [τ₂]) = unify(τ₁, τ₂)

unify(Maybe τ₁, Maybe τ₂) = unify(τ₁, τ₂)

unify(Result[τ₁, τ₂], Result[τ₃, τ₄]) =
    let S₁ = unify(τ₁, τ₃) in
    let S₂ = unify(S₁(τ₂), S₁(τ₄)) in
    S₂ ∘ S₁

unify((τ₁,...,τₙ) → τ, (τ'₁,...,τ'ₙ) → τ') =
    let S₁ = unify(τ₁, τ'₁) in
    ...
    let Sₙ = unify(Sₙ₋₁(...S₁(τₙ)...), Sₙ₋₁(...S₁(τ'ₙ)...)) in
    let Sᵣ = unify(Sₙ(...S₁(τ)...), Sₙ(...S₁(τ')...)) in
    Sᵣ ∘ Sₙ ∘ ... ∘ S₁

unify(_, _) = fail
```

### 3.3 Unification Properties

**Theorem 3.1 (Correctness):** If `unify(τ₁, τ₂) = S`, then `S(τ₁) = S(τ₂)`.

**Theorem 3.2 (Most General):** If `unify(τ₁, τ₂) = S` and S' also unifies τ₁ and τ₂, then there exists S'' such that S' = S'' ∘ S.

**Theorem 3.3 (Termination):** The unification algorithm terminates on all inputs.

**Proof:** The size of types strictly decreases in recursive calls, and the occurs check prevents infinite types. □

**Theorem 3.4 (Decidability):** Unifiability is decidable.

---

## 4. Algorithm W

Algorithm W is the core type inference algorithm for WokeLang.

### 4.1 Instantiation

```
inst(∀α₁...αₙ.τ) = [α₁ ↦ β₁, ..., αₙ ↦ βₙ](τ)
    where β₁,...,βₙ are fresh type variables
```

### 4.2 Generalization

```
gen(Γ, τ) = ∀α₁...αₙ.τ
    where {α₁,...,αₙ} = FTV(τ) \ FTV(Γ)
```

### 4.3 Algorithm W Definition

```
W(Γ, e) → (S, τ)  -- Returns substitution and inferred type
```

#### Literals

```
W(Γ, n) = (id, Int)              where n is integer literal
W(Γ, f) = (id, Float)            where f is float literal
W(Γ, s) = (id, String)           where s is string literal
W(Γ, true) = W(Γ, false) = (id, Bool)
W(Γ, unit) = (id, Unit)
```

#### Variables

```
W(Γ, x) =
    if x ∉ dom(Γ) then fail "undefined variable"
    else (id, inst(Γ(x)))
```

#### Binary Operations

```
W(Γ, e₁ + e₂) =
    let (S₁, τ₁) = W(Γ, e₁) in
    let (S₂, τ₂) = W(S₁(Γ), e₂) in
    let S₃ = unify(S₂(τ₁), τ₂) in
    case S₃(S₂(τ₁)) of
        Int → (S₃ ∘ S₂ ∘ S₁, Int)
        Float → (S₃ ∘ S₂ ∘ S₁, Float)
        String → (S₃ ∘ S₂ ∘ S₁, String)
        _ → fail "type error in +"
```

#### Function Application

```
W(Γ, f(e₁,...,eₙ)) =
    let σ = Γ(f) in
    let (τ₁,...,τₙ) → τᵣ = inst(σ) in
    let (S₁, τ'₁) = W(Γ, e₁) in
    let U₁ = unify(S₁(τ₁), τ'₁) in
    ...
    let (Sₙ, τ'ₙ) = W(Uₙ₋₁ ∘ ... ∘ U₁ ∘ Sₙ₋₁ ∘ ... ∘ S₁(Γ), eₙ) in
    let Uₙ = unify(Sₙ ∘ ... ∘ S₁(τₙ), τ'ₙ) in
    (Uₙ ∘ Sₙ ∘ ... ∘ U₁ ∘ S₁, Uₙ ∘ ... ∘ U₁ ∘ Sₙ ∘ ... ∘ S₁(τᵣ))
```

#### Lambda/Function Definition

```
W(Γ, λx.e) =
    let α = fresh type variable in
    let (S, τ) = W(Γ[x ↦ α], e) in
    (S, S(α) → τ)
```

#### Let Binding (remember)

```
W(Γ, remember x = e₁; e₂) =
    let (S₁, τ₁) = W(Γ, e₁) in
    let σ = gen(S₁(Γ), τ₁) in
    let (S₂, τ₂) = W(S₁(Γ)[x ↦ σ], e₂) in
    (S₂ ∘ S₁, τ₂)
```

#### Conditional

```
W(Γ, when e₁ { e₂ } otherwise { e₃ }) =
    let (S₁, τ₁) = W(Γ, e₁) in
    let U₁ = unify(τ₁, Bool) in
    let (S₂, τ₂) = W(U₁ ∘ S₁(Γ), e₂) in
    let (S₃, τ₃) = W(S₂ ∘ U₁ ∘ S₁(Γ), e₃) in
    let U₂ = unify(S₃(τ₂), τ₃) in
    (U₂ ∘ S₃ ∘ S₂ ∘ U₁ ∘ S₁, U₂(τ₃))
```

#### Arrays

```
W(Γ, [e₁,...,eₙ]) =
    if n = 0 then
        let α = fresh in (id, [α])
    else
        let (S₁, τ₁) = W(Γ, e₁) in
        ...
        let (Sₙ, τₙ) = W(Sₙ₋₁ ∘ ... ∘ S₁(Γ), eₙ) in
        let U = unifyAll(Sₙ ∘ ... ∘ S₂(τ₁), ..., τₙ) in
        (U ∘ Sₙ ∘ ... ∘ S₁, [U(τₙ)])
```

#### Result Constructors

```
W(Γ, Okay(e)) =
    let (S, τ) = W(Γ, e) in
    let α = fresh in
    (S, Result[τ, α])

W(Γ, Oops(e)) =
    let (S, τ) = W(Γ, e) in
    let U = unify(τ, String) in
    let α = fresh in
    (U ∘ S, Result[α, String])
```

---

## 5. Soundness and Completeness

### 5.1 Soundness

**Theorem 5.1 (Algorithm W Soundness):** If `W(Γ, e) = (S, τ)`, then `S(Γ) ⊢ e : τ`.

**Proof:** By structural induction on the expression e.

**Case e = x:**
- W(Γ, x) = (id, inst(Γ(x)))
- Γ(x) = σ and inst(σ) = τ where σ = ∀ᾱ.τ₀ and τ = τ₀[ᾱ ↦ β̄]
- By [T-Var] and instantiation, Γ ⊢ x : τ ✓

**Case e = e₁ + e₂:**
- By IH, S₁(Γ) ⊢ e₁ : τ₁ and S₂S₁(Γ) ⊢ e₂ : τ₂
- S₃ unifies S₂τ₁ and τ₂
- By [T-Add-*], S₃S₂S₁(Γ) ⊢ e₁ + e₂ : S₃S₂τ₁ ✓

Other cases follow similarly by IH and the typing rules. □

### 5.2 Completeness

**Theorem 5.2 (Algorithm W Completeness):** If `Γ ⊢ e : τ`, then `W(Γ, e) = (S, τ')` for some S, τ' such that there exists R with `R(τ') = τ` and `R ∘ S ≡ S` on FTV(Γ).

**Proof:** By structural induction on the typing derivation. The key insight is that W computes principal types. □

### 5.3 Principal Type Property

**Theorem 5.3 (Principal Types):** If e is typeable in Γ, then W computes its principal type scheme.

**Definition:** σ is a principal type scheme of e in Γ if:
1. Γ ⊢ e : σ
2. For all σ' such that Γ ⊢ e : σ', we have σ' = S(σ) for some substitution S

---

## 6. Extensions for WokeLang

### 6.1 Result Type Inference

WokeLang extends standard HM with Result types:

```
W(Γ, decide based on e { Okay(x) → e₁; Oops(y) → e₂ }) =
    let (S₁, τ) = W(Γ, e) in
    let αok, αerr = fresh in
    let U₁ = unify(τ, Result[αok, αerr]) in
    let (S₂, τ₁) = W(U₁S₁(Γ)[x ↦ U₁(αok)], e₁) in
    let (S₃, τ₂) = W(S₂U₁S₁(Γ)[y ↦ S₂U₁(αerr)], e₂) in
    let U₂ = unify(S₃(τ₁), τ₂) in
    (U₂ ∘ S₃ ∘ S₂ ∘ U₁ ∘ S₁, U₂(τ₂))
```

### 6.2 Widening Rule

WokeLang allows Int to widen to Float:

```
unify(Int, Float) = [promote]
unify(Float, Int) = [promote]
```

This is implemented via a special "widening" substitution that doesn't fail but instead promotes Int to Float.

### 6.3 Type Annotations

When explicit type annotations are provided:

```
W(Γ, remember x: τ = e) =
    let (S, τ') = W(Γ, e) in
    let U = unify(τ', τ) in
    (U ∘ S, τ)
```

---

## 7. Complexity Analysis

### 7.1 Time Complexity

**Theorem 7.1:** Algorithm W runs in O(n²) time in the worst case, where n is the size of the expression.

This is due to the occurs check in unification, which must traverse the entire type.

### 7.2 Space Complexity

**Theorem 7.2:** Algorithm W uses O(n) space for the substitution.

### 7.3 Practical Performance

In practice, WokeLang programs have small types, and inference is nearly linear.

---

## 8. Implementation Correspondence

The algorithm corresponds to `src/typechecker/mod.rs`:

| Algorithm Component | Implementation |
|---------------------|----------------|
| Fresh type variable | `fresh_type_var()` method |
| Unification | `unify()` method |
| Substitution application | `apply_substitutions()` method |
| Type environment | `TypeEnv` struct |
| Inference | `infer_expr()` method |
| AST to internal type | `ast_type_to_inferred()` method |

---

## 9. Error Messages

When unification fails, WokeLang provides informative errors:

```rust
TypeError::TypeMismatch { expected, actual }
TypeError::ArityMismatch { expected, actual }
TypeError::UndefinedVariable(name)
TypeError::UndefinedFunction(name)
```

**TODO:** Implement better error recovery and multi-error reporting.

---

## References

1. Milner, R. (1978). "A Theory of Type Polymorphism in Programming"
2. Damas, L. and Milner, R. (1982). "Principal Type-Schemes for Functional Programs"
3. Hindley, R. (1969). "The Principal Type-Scheme of an Object in Combinatory Logic"
4. Robinson, J.A. (1965). "A Machine-Oriented Logic Based on the Resolution Principle"
5. Lee, O. and Yi, K. (1998). "Proofs about a Folklore Let-Polymorphic Type Inference Algorithm"
