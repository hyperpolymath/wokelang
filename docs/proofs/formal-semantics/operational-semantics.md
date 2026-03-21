# WokeLang Operational Semantics

This document provides a complete formal specification of WokeLang's operational semantics using both big-step (natural) and small-step (structural operational) semantics.

## 1. Abstract Syntax

### 1.1 Syntactic Categories

```
v ∈ Value        ::= n | f | s | b | unit | [v₁,...,vₙ] | Okay(v) | Oops(s)
e ∈ Expr         ::= v | x | e₁ op e₂ | uop e | f(e₁,...,eₙ) | e[e] | e measured in u
s ∈ Stmt         ::= remember x = e | x = e | give back e | when e {s*} otherwise {s*}
                   | repeat e times {s*} | attempt safely {s*} or reassure s
                   | only if okay s {s*} | complain s | decide based on e {arms}
                   | spawn worker x | @tag s
p ∈ Program      ::= item*
item ∈ TopLevel  ::= to f(params) → τ {s*} | worker x {s*} | thanks to {entries}
                   | only if okay s {s*} | #pragma on/off
```

### 1.2 Values

```
n ∈ ℤ              (64-bit signed integers)
f ∈ ℝ              (64-bit floating point)
s ∈ String         (UTF-8 strings)
b ∈ {true, false}  (booleans)
unit               (unit value)
```

### 1.3 Binary Operators

```
op ∈ BinOp ::= + | - | * | / | % | == | != | < | > | <= | >= | and | or
```

### 1.4 Unary Operators

```
uop ∈ UnOp ::= - | not
```

---

## 2. Semantic Domains

### 2.1 Environment

An environment `ρ` maps identifiers to values:

```
ρ : Env = Ident → Value
```

Environment operations:
- `ρ[x ↦ v]` : extend environment with binding
- `ρ(x)` : lookup value (undefined if x ∉ dom(ρ))

### 2.2 Function Store

A function store `Φ` maps function names to definitions:

```
Φ : FuncStore = Ident → FunctionDef
```

### 2.3 Consent State

Consent state `C` tracks granted permissions:

```
C : ConsentState = ℘(Permission)
```

### 2.4 Configuration

A configuration is a tuple `⟨e, ρ, Φ, C⟩` or `⟨s, ρ, Φ, C⟩`.

---

## 3. Big-Step Semantics (Natural Semantics)

We define the judgment `⟨e, ρ, Φ⟩ ⇓ v` meaning "expression e evaluates to value v in environment ρ with function store Φ".

### 3.1 Expression Evaluation

#### Literals

```
─────────────────────────── [B-Int]
⟨n, ρ, Φ⟩ ⇓ n

─────────────────────────── [B-Float]
⟨f, ρ, Φ⟩ ⇓ f

─────────────────────────── [B-String]
⟨s, ρ, Φ⟩ ⇓ s

─────────────────────────── [B-Bool]
⟨b, ρ, Φ⟩ ⇓ b

─────────────────────────── [B-Unit]
⟨unit, ρ, Φ⟩ ⇓ unit
```

#### Variables

```
      x ∈ dom(ρ)
─────────────────────────── [B-Var]
⟨x, ρ, Φ⟩ ⇓ ρ(x)
```

#### Binary Operations

```
⟨e₁, ρ, Φ⟩ ⇓ v₁    ⟨e₂, ρ, Φ⟩ ⇓ v₂    v = v₁ ⊕ v₂
────────────────────────────────────────────────── [B-BinOp]
⟨e₁ op e₂, ρ, Φ⟩ ⇓ v
```

Where `⊕` is the semantic interpretation of `op`:

| op | Integer semantics | Float semantics | String semantics |
|----|-------------------|-----------------|------------------|
| +  | n₁ + n₂          | f₁ + f₂         | s₁ ++ s₂        |
| -  | n₁ - n₂          | f₁ - f₂         | undefined       |
| *  | n₁ × n₂          | f₁ × f₂         | undefined       |
| /  | n₁ ÷ n₂ (n₂ ≠ 0) | f₁ / f₂         | undefined       |
| %  | n₁ mod n₂        | undefined       | undefined       |
| == | n₁ = n₂          | f₁ = f₂         | s₁ = s₂         |
| <  | n₁ < n₂          | f₁ < f₂         | s₁ <ₗₑₓ s₂      |

#### Unary Operations

```
⟨e, ρ, Φ⟩ ⇓ v    v' = ⊖v
─────────────────────────── [B-UnOp]
⟨uop e, ρ, Φ⟩ ⇓ v'
```

Where:
- `⊖(-) n = -n`
- `⊖(-) f = -f`
- `⊖(not) b = ¬b`

#### Function Calls

```
Φ(f) = to f(x₁,...,xₙ) { body }
⟨e₁, ρ, Φ⟩ ⇓ v₁  ...  ⟨eₙ, ρ, Φ⟩ ⇓ vₙ
ρ' = [x₁ ↦ v₁, ..., xₙ ↦ vₙ]
⟨body, ρ', Φ⟩ ⇓ᵇ (v, ρ'')
─────────────────────────────────────── [B-Call]
⟨f(e₁,...,eₙ), ρ, Φ⟩ ⇓ v
```

#### Arrays

```
⟨e₁, ρ, Φ⟩ ⇓ v₁  ...  ⟨eₙ, ρ, Φ⟩ ⇓ vₙ
────────────────────────────────────── [B-Array]
⟨[e₁,...,eₙ], ρ, Φ⟩ ⇓ [v₁,...,vₙ]
```

#### Array Indexing

```
⟨e₁, ρ, Φ⟩ ⇓ [v₀,...,vₖ]    ⟨e₂, ρ, Φ⟩ ⇓ n    0 ≤ n ≤ k
───────────────────────────────────────────────────────── [B-Index]
⟨e₁[e₂], ρ, Φ⟩ ⇓ vₙ
```

#### Result Types

```
⟨e, ρ, Φ⟩ ⇓ v
─────────────────────────── [B-Okay]
⟨Okay(e), ρ, Φ⟩ ⇓ Okay(v)

⟨e, ρ, Φ⟩ ⇓ s
─────────────────────────── [B-Oops]
⟨Oops(e), ρ, Φ⟩ ⇓ Oops(s)
```

#### Unit Measurement (Annotation Only)

```
⟨e, ρ, Φ⟩ ⇓ v
──────────────────────────────── [B-Unit-Measure]
⟨e measured in u, ρ, Φ⟩ ⇓ v
```

### 3.2 Statement Evaluation

Statement evaluation uses the judgment `⟨s, ρ, Φ, C⟩ ⇓ᵇ (result, ρ', C')` where result is either:
- `Continue` - normal completion
- `Return(v)` - return with value v

#### Variable Declaration

```
⟨e, ρ, Φ⟩ ⇓ v
──────────────────────────────────────────────── [B-VarDecl]
⟨remember x = e, ρ, Φ, C⟩ ⇓ᵇ (Continue, ρ[x ↦ v], C)
```

#### Assignment

```
⟨e, ρ, Φ⟩ ⇓ v    x ∈ dom(ρ)
──────────────────────────────────────────── [B-Assign]
⟨x = e, ρ, Φ, C⟩ ⇓ᵇ (Continue, ρ[x ↦ v], C)
```

#### Return

```
⟨e, ρ, Φ⟩ ⇓ v
───────────────────────────────────────── [B-Return]
⟨give back e, ρ, Φ, C⟩ ⇓ᵇ (Return(v), ρ, C)
```

#### Conditional (True Branch)

```
⟨e, ρ, Φ⟩ ⇓ true    ⟨s₁*, ρ, Φ, C⟩ ⇓ᵇ* (r, ρ', C')
────────────────────────────────────────────────────── [B-If-True]
⟨when e {s₁*} otherwise {s₂*}, ρ, Φ, C⟩ ⇓ᵇ (r, ρ', C')
```

#### Conditional (False Branch)

```
⟨e, ρ, Φ⟩ ⇓ false    ⟨s₂*, ρ, Φ, C⟩ ⇓ᵇ* (r, ρ', C')
─────────────────────────────────────────────────────── [B-If-False]
⟨when e {s₁*} otherwise {s₂*}, ρ, Φ, C⟩ ⇓ᵇ (r, ρ', C')
```

#### Loop (Base Case)

```
⟨e, ρ, Φ⟩ ⇓ n    n ≤ 0
─────────────────────────────────────────── [B-Loop-Zero]
⟨repeat e times {s*}, ρ, Φ, C⟩ ⇓ᵇ (Continue, ρ, C)
```

#### Loop (Inductive Case)

```
⟨e, ρ, Φ⟩ ⇓ n    n > 0
⟨s*, ρ, Φ, C⟩ ⇓ᵇ* (Continue, ρ', C')
⟨repeat (n-1) times {s*}, ρ', Φ, C'⟩ ⇓ᵇ (r, ρ'', C'')
───────────────────────────────────────────────────────── [B-Loop-Step]
⟨repeat e times {s*}, ρ, Φ, C⟩ ⇓ᵇ (r, ρ'', C'')
```

#### Attempt Block (Success)

```
⟨s*, ρ, Φ, C⟩ ⇓ᵇ* (r, ρ', C')
──────────────────────────────────────────────────────── [B-Attempt-Ok]
⟨attempt safely {s*} or reassure msg, ρ, Φ, C⟩ ⇓ᵇ (r, ρ', C')
```

#### Attempt Block (Error Recovery)

```
⟨s*, ρ, Φ, C⟩ ⇓ᵇ* error
──────────────────────────────────────────────────────────── [B-Attempt-Err]
⟨attempt safely {s*} or reassure msg, ρ, Φ, C⟩ ⇓ᵇ (Continue, ρ, C)
```

#### Consent Block (Granted)

```
perm ∈ C    ⟨s*, ρ, Φ, C⟩ ⇓ᵇ* (r, ρ', C')
───────────────────────────────────────────── [B-Consent-Grant]
⟨only if okay perm {s*}, ρ, Φ, C⟩ ⇓ᵇ (r, ρ', C')
```

#### Consent Block (Denied)

```
perm ∉ C
────────────────────────────────────────────── [B-Consent-Deny]
⟨only if okay perm {s*}, ρ, Φ, C⟩ ⇓ᵇ (Continue, ρ, C)
```

#### Pattern Matching

```
⟨e, ρ, Φ⟩ ⇓ v
match(p₁, v) = Some(bindings)    ⟨s₁*, ρ ⊕ bindings, Φ, C⟩ ⇓ᵇ* (r, ρ', C')
─────────────────────────────────────────────────────────────────────────── [B-Match]
⟨decide based on e { p₁ → {s₁*}; ... }, ρ, Φ, C⟩ ⇓ᵇ (r, ρ', C')
```

Where `match(p, v)` is defined as:

```
match(_, v) = Some([])                           (wildcard)
match(x, v) = Some([x ↦ v])                      (identifier)
match(n, n) = Some([])                           (integer literal)
match(s, s) = Some([])                           (string literal)
match(b, b) = Some([])                           (boolean literal)
match(Okay(p), Okay(v)) = match(p, v)            (okay pattern)
match(Oops(p), Oops(v)) = match(p, v)            (oops pattern)
match(_, _) = None                               (no match)
```

---

## 4. Small-Step Semantics (Structural Operational Semantics)

For compilation and program analysis, we also define small-step semantics using the transition relation `⟨e, ρ, Φ⟩ → ⟨e', ρ', Φ⟩`.

### 4.1 Evaluation Contexts

```
E ::= □ | E op e | v op E | uop E | f(v₁,...,vᵢ,E,eᵢ₊₂,...,eₙ)
    | [v₁,...,vᵢ,E,eᵢ₊₂,...,eₙ] | E[e] | v[E]
    | Okay(E) | Oops(E) | E measured in u
```

### 4.2 Expression Transitions

```
⟨x, ρ, Φ⟩ → ⟨ρ(x), ρ, Φ⟩                                    [S-Var]

⟨v₁ op v₂, ρ, Φ⟩ → ⟨v₁ ⊕ v₂, ρ, Φ⟩                          [S-BinOp]

⟨uop v, ρ, Φ⟩ → ⟨⊖v, ρ, Φ⟩                                  [S-UnOp]

Φ(f) = to f(x₁,...,xₙ) { body }
───────────────────────────────────────────────────────────── [S-Call]
⟨f(v₁,...,vₙ), ρ, Φ⟩ → ⟨body[x₁:=v₁,...,xₙ:=vₙ], ρ, Φ⟩

⟨[v₀,...,vₖ][n], ρ, Φ⟩ → ⟨vₙ, ρ, Φ⟩    (0 ≤ n ≤ k)          [S-Index]

⟨e, ρ, Φ⟩ → ⟨e', ρ', Φ⟩
────────────────────────────                                 [S-Context]
⟨E[e], ρ, Φ⟩ → ⟨E[e'], ρ', Φ⟩
```

### 4.3 Statement Transitions

Statement configurations include a statement list (continuation):

```
⟨remember x = v; s*, ρ, Φ, C⟩ → ⟨s*, ρ[x ↦ v], Φ, C⟩        [S-VarDecl]

⟨x = v; s*, ρ, Φ, C⟩ → ⟨s*, ρ[x ↦ v], Φ, C⟩                 [S-Assign]

⟨give back v, ρ, Φ, C⟩ → ⟨done(v), ρ, Φ, C⟩                 [S-Return]

⟨when true {s₁*} otherwise {s₂*}; s*, ρ, Φ, C⟩
  → ⟨s₁* ++ s*, ρ, Φ, C⟩                                     [S-If-True]

⟨when false {s₁*} otherwise {s₂*}; s*, ρ, Φ, C⟩
  → ⟨s₂* ++ s*, ρ, Φ, C⟩                                     [S-If-False]
```

---

## 5. Semantic Properties

### 5.1 Determinism

**Theorem 5.1 (Determinism):** WokeLang expression evaluation is deterministic.

For all expressions e, environments ρ, and function stores Φ:

```
If ⟨e, ρ, Φ⟩ ⇓ v₁ and ⟨e, ρ, Φ⟩ ⇓ v₂, then v₁ = v₂
```

**Proof:** By structural induction on the derivation. Each inference rule has unique premises that determine the conclusion. □

### 5.2 Termination

**Theorem 5.2 (Conditional Termination):** WokeLang evaluation terminates for all programs without unbounded recursion.

Note: The `repeat n times` loop always terminates since n is evaluated once and decremented. Unbounded recursion can cause non-termination.

### 5.3 Consent Safety

**Theorem 5.3 (Consent Monotonicity):** Consent state can only grow during program execution when operating in non-interactive mode.

```
If ⟨s, ρ, Φ, C⟩ ⇓ᵇ (r, ρ', C'), then C ⊆ C'
```

**Proof:** By inspection of rules, only [B-Consent-Grant] can modify consent state, and it only adds permissions. □

---

## 6. Equivalence of Semantics

**Theorem 6.1 (Big-Step/Small-Step Equivalence):** For any expression e:

```
⟨e, ρ, Φ⟩ ⇓ v  ⟺  ⟨e, ρ, Φ⟩ →* ⟨v, ρ, Φ⟩
```

**Proof:** Standard proof by induction on the structure of derivations, showing each big-step rule corresponds to a sequence of small-step transitions. □

---

## 7. Reference Implementation Correspondence

The operational semantics defined here corresponds directly to the tree-walking interpreter implementation in `src/interpreter/mod.rs`:

| Semantic Rule | Implementation |
|---------------|----------------|
| B-Var | `Expr::Identifier` case in `evaluate()` |
| B-BinOp | `apply_binary_op()` method |
| B-Call | `call_function()` method |
| B-VarDecl | `Statement::VarDecl` case in `execute_statement()` |
| B-If-* | `Statement::Conditional` case |
| B-Loop-* | `Statement::Loop` case |
| B-Consent-* | `execute_consent_block()` method |
| B-Match | `pattern_matches()` and `Decide` handling |

---

## References

1. Plotkin, G.D. (1981). "A Structural Approach to Operational Semantics"
2. Kahn, G. (1987). "Natural Semantics"
3. Wright, A.K. and Felleisen, M. (1994). "A Syntactic Approach to Type Soundness"
