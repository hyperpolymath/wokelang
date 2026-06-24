<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Category Theory Foundations for WokeLang

This document provides the category-theoretic foundations underlying WokeLang's type system and semantics.

## 1. Categories and Types

### 1.1 The Category of Types

WokeLang types form a category **WokeType** where:

- **Objects:** Types (Int, Float, String, Bool, Unit, [τ], Maybe τ, Result[τ,ε], (τ₁,...,τₙ) → τ)
- **Morphisms:** Type-preserving functions (terms of function type)
- **Identity:** λx.x : τ → τ
- **Composition:** (g ∘ f)(x) = g(f(x))

### 1.2 Categorical Constructs

#### 1.2.1 Terminal Object

```
Unit (𝟙) is the terminal object:
∀τ. ∃! unit : τ → Unit
```

The unique morphism to Unit is `λ_.unit`.

#### 1.2.2 Initial Object

```
⊥ (bottom/void) is the initial object:
∀τ. ∃! absurd : ⊥ → τ
```

WokeLang doesn't have an explicit void type, but runtime errors can be viewed as ⊥.

#### 1.2.3 Products

```
τ₁ × τ₂ = { x: τ₁, y: τ₂ } (record types)
π₁ : τ₁ × τ₂ → τ₁
π₂ : τ₁ × τ₂ → τ₂
⟨f, g⟩ : σ → τ₁ × τ₂ when f : σ → τ₁ and g : σ → τ₂
```

#### 1.2.4 Coproducts

```
τ₁ + τ₂ = Variant1(τ₁) | Variant2(τ₂) (sum types)
ι₁ : τ₁ → τ₁ + τ₂
ι₂ : τ₂ → τ₁ + τ₂
[f, g] : τ₁ + τ₂ → σ when f : τ₁ → σ and g : τ₂ → σ
```

#### 1.2.5 Exponentials

```
τ₂^τ₁ = τ₁ → τ₂ (function types)
eval : (τ₂^τ₁) × τ₁ → τ₂
curry : (σ × τ₁ → τ₂) → (σ → τ₂^τ₁)
```

**Theorem 1.1:** WokeType is a cartesian closed category (CCC).

---

## 2. Functors

### 2.1 The Array Functor

`[-] : WokeType → WokeType` is a functor:

```
Objects: τ ↦ [τ]
Morphisms: (f : τ₁ → τ₂) ↦ (map f : [τ₁] → [τ₂])

Functor Laws:
  map id = id
  map (g ∘ f) = map g ∘ map f
```

### 2.2 The Maybe Functor

`Maybe : WokeType → WokeType` is a functor:

```
Objects: τ ↦ Maybe τ
Morphisms: (f : τ₁ → τ₂) ↦ (fmap f : Maybe τ₁ → Maybe τ₂)
  where fmap f Nothing = Nothing
        fmap f (Just x) = Just (f x)

Functor Laws:
  fmap id = id
  fmap (g ∘ f) = fmap g ∘ fmap f
```

### 2.3 The Result Functor

For fixed error type ε, `Result[-, ε] : WokeType → WokeType` is a functor:

```
Objects: τ ↦ Result[τ, ε]
Morphisms: (f : τ₁ → τ₂) ↦ (fmap f : Result[τ₁, ε] → Result[τ₂, ε])
  where fmap f (Oops e) = Oops e
        fmap f (Okay x) = Okay (f x)
```

---

## 3. Monads

### 3.1 The Maybe Monad

Maybe forms a monad with:

```
η (return) : τ → Maybe τ
η x = Just x

μ (join) : Maybe (Maybe τ) → Maybe τ
μ Nothing = Nothing
μ (Just Nothing) = Nothing
μ (Just (Just x)) = Just x

(>>=) : Maybe τ₁ → (τ₁ → Maybe τ₂) → Maybe τ₂
Nothing >>= f = Nothing
Just x >>= f = f x
```

**Monad Laws:**
```
η x >>= f = f x                    (left identity)
m >>= η = m                        (right identity)
(m >>= f) >>= g = m >>= (λx. f x >>= g)   (associativity)
```

### 3.2 The Result Monad

Result[τ, ε] forms a monad for fixed ε:

```
η : τ → Result[τ, ε]
η x = Okay x

(>>=) : Result[τ₁, ε] → (τ₁ → Result[τ₂, ε]) → Result[τ₂, ε]
Oops e >>= f = Oops e
Okay x >>= f = f x
```

This is the basis for `attempt safely` and the `?` operator.

### 3.3 The State Monad

The interpreter can be viewed through the State monad:

```
State s a = s → (a, s)

η x = λs. (x, s)
m >>= f = λs. let (a, s') = m s in f a s'
```

Where s = (Environment, Consent, FunctionStore).

### 3.4 The Consent Monad

We can define a Consent monad:

```
Consent a = ConsentState → (a + Denied, ConsentState)

η x = λc. (Okay x, c)
m >>= f = λc.
    let (r, c') = m c in
    case r of
        Oops e → (Oops e, c')
        Okay a → f a c'
```

### 3.5 Monad Transformers

Complex effects combine via transformers:

```
ExceptT ε (StateT s IO) a
= s → IO (Either ε a, s)
```

For WokeLang:
```
WokeM a = ConsentT (ResultT String (StateT Env IO)) a
```

---

## 4. Algebraic Data Types

### 4.1 Polynomial Functors

WokeLang ADTs are polynomial functors:

```
data List a = Nil | Cons a (List a)

ListF a x = 1 + a × x
List a = μx. ListF a x = μx. 1 + a × x
```

### 4.2 Initial Algebras

**Definition:** An F-algebra is a pair (A, α : F A → A).

**Definition:** An initial F-algebra is an F-algebra (μF, in : F(μF) → μF) such that for any F-algebra (A, α), there exists a unique morphism (catamorphism) ⦇α⦈ : μF → A.

```
         F ⦇α⦈
F(μF) ────────→ F A
  │               │
in│               │α
  ↓               ↓
 μF ─────────→ A
        ⦇α⦈
```

### 4.3 Catamorphisms (Folds)

For List:
```
foldr : (a → b → b) → b → [a] → b
foldr f z [] = z
foldr f z (x:xs) = f x (foldr f z xs)
```

This is the catamorphism for the List functor.

---

## 5. Natural Transformations

### 5.1 Definition

A natural transformation η : F ⟹ G between functors F, G : C → D is a family of morphisms:

```
ηₐ : F(A) → G(A)
```

Such that for all f : A → B:
```
G(f) ∘ ηₐ = η_B ∘ F(f)
```

### 5.2 Examples in WokeLang

#### Maybe to Result

```
maybeToResult : ∀τ ε. Maybe τ → Result[τ, ε]
maybeToResult Nothing = Oops "Nothing"
maybeToResult (Just x) = Okay x
```

#### Array to Maybe

```
headMaybe : ∀τ. [τ] → Maybe τ
headMaybe [] = Nothing
headMaybe (x:_) = Just x
```

---

## 6. Adjunctions

### 6.1 Free-Forgetful Adjunction

The relationship between WokeLang and untyped evaluation:

```
Free : Set → WokeType
Forgetful : WokeType → Set

Free ⊣ Forgetful
```

### 6.2 Currying Adjunction

```
- × A ⊣ (-)^A

Hom(B × A, C) ≅ Hom(B, C^A)
```

This is the basis for curry/uncurry:

```
curry : ((A × B) → C) → (A → (B → C))
uncurry : (A → (B → C)) → ((A × B) → C)
```

---

## 7. Limits and Colimits

### 7.1 Limits

**Theorem 7.1:** WokeType has all finite limits.

- Products: Record types
- Equalizers: Subtyping (limited)
- Pullbacks: Intersection types (not implemented)

### 7.2 Colimits

**Theorem 7.2:** WokeType has all finite colimits.

- Coproducts: Sum types (enums)
- Coequalizers: Quotient types (not implemented)
- Pushouts: (not implemented)

---

## 8. Topos Structure

### 8.1 Subobject Classifier

If WokeLang had a Bool type acting as Ω:

```
true : 1 → Bool
χₘ : A → Bool (characteristic function of subobject m)
```

For predicate P on type A:
```
{ x : A | P(x) } ←→ P : A → Bool
```

### 8.2 Power Objects

```
℘(A) = A → Bool
```

Not directly representable in WokeLang without dependent types.

---

## 9. Yoneda Lemma

### 9.1 Statement

For any functor F : C → Set and object A in C:

```
Nat(Hom(A, -), F) ≅ F(A)
```

### 9.2 Application to Types

For WokeLang types:
```
∀R. (τ → R) → F R ≅ F τ
```

This underlies continuation-passing style transformations.

---

## 10. Semantics Categories

### 10.1 The Category of Domains

For denotational semantics:

- **Objects:** CPOs (complete partial orders) with ⊥
- **Morphisms:** Continuous (Scott-continuous) functions
- **Limits:** Bilimits exist for domain equations

### 10.2 Solving Domain Equations

```
Value ≅ Int + Float + String + Bool + 1 + Value* + (Value + String) + (Value →ᶜ Value⊥)
```

Solved using:
1. Bilimit construction
2. Information systems
3. Inverse limit construction

---

## 11. Linear and Affine Types (Future)

### 11.1 Linear Logic Interpretation

Future WokeLang could add linear types:

```
τ ⊗ σ : Linear tensor (both consumed)
τ & σ : Additive conjunction (choose one)
τ ⊕ σ : Additive disjunction (sum type)
!τ : Of course (unlimited use)
```

### 11.2 Relevance to Resources

Linear types ensure resources (like Result values) are used exactly once:

```
remember r : !Result[A, E] = operation();
// r must be matched/unwrapped exactly once
```

---

## 12. Categorical Semantics Summary

| WokeLang Construct | Categorical Concept |
|-------------------|---------------------|
| Types | Objects in CCC |
| Functions | Morphisms (exponential) |
| Unit | Terminal object |
| Records | Products |
| Enums | Coproducts |
| Arrays | List functor (initial algebra) |
| Maybe | Option monad |
| Result | Error monad |
| Consent blocks | Graded monad / Effect |
| Type inference | Universal property |

---

## References

1. Mac Lane, S. (1971). "Categories for the Working Mathematician"
2. Awodey, S. (2010). "Category Theory"
3. Pierce, B.C. (1991). "Basic Category Theory for Computer Scientists"
4. Barr, M. and Wells, C. (1990). "Category Theory for Computing Science"
5. Wadler, P. (1992). "Monads for Functional Programming"
6. Moggi, E. (1991). "Notions of Computation and Monads"
7. Lambek, J. and Scott, P.J. (1986). "Introduction to Higher Order Categorical Logic"
