# WokeLang Capability-Based Security Proofs

This document provides formal proofs of security properties for WokeLang's capability-based security system (Superpowers).

## 1. Capability Model

### 1.1 Capability Definition

```
c ∈ Capability ::= FileRead(path?)
                 | FileWrite(path?)
                 | Execute(cmd?)
                 | Network(host?)
                 | Environment(var?)
                 | Process
                 | SystemInfo
                 | Crypto
                 | Clipboard
                 | Notify
                 | Custom(name)
```

The optional parameters represent scoping: `None` means wildcard (all), `Some(x)` means specific resource x.

### 1.2 Capability Set

```
C ∈ CapabilitySet = ℘(Capability)
```

### 1.3 Granted Capability

```
g ∈ GrantedCapability = {
    capability: Capability,
    granted_at: Timestamp,
    expires_at: Option<Timestamp>,
    granted_by: Principal,
    revoked: Bool
}
```

### 1.4 Validity Predicate

```
valid(g) = ¬g.revoked ∧ (g.expires_at = None ∨ now() < g.expires_at)
```

---

## 2. Capability Algebra

### 2.1 Subsumption Relation

Capability c₁ subsumes c₂ (written c₁ ⊇ c₂) if possessing c₁ grants the rights of c₂.

```
FileRead(None) ⊇ FileRead(Some(p))     ∀p
FileWrite(None) ⊇ FileWrite(Some(p))   ∀p
Execute(None) ⊇ Execute(Some(c))       ∀c
Network(None) ⊇ Network(Some(h))       ∀h
Environment(None) ⊇ Environment(Some(v)) ∀v
c ⊇ c                                   (reflexivity)
```

### 2.2 Subsumption Properties

**Theorem 2.1 (Reflexivity):** ∀c. c ⊇ c

**Theorem 2.2 (Transitivity):** If c₁ ⊇ c₂ and c₂ ⊇ c₃, then c₁ ⊇ c₃

**Theorem 2.3 (Antisymmetry):** If c₁ ⊇ c₂ and c₂ ⊇ c₁, then c₁ = c₂

**Proof:** The subsumption relation forms a partial order. Wildcard capabilities are maximal elements within their category. □

### 2.3 Capability Satisfaction

A capability set C satisfies a required capability c (written C ⊨ c):

```
C ⊨ c  ⟺  ∃c' ∈ C. c' ⊇ c
```

---

## 3. Security State Machine

### 3.1 Security State

```
σ ∈ SecurityState = {
    registry: Scope → List<GrantedCapability>,
    pending: Set<Capability>,
    audit_log: List<AuditEntry>
}
```

### 3.2 Security Actions

```
a ∈ Action ::= Grant(scope, capability, principal)
             | Revoke(scope, capability)
             | Request(scope, capability)
             | Use(scope, capability)
             | Cleanup
```

### 3.3 Transition Rules

#### Grant

```
                  g = GrantedCapability(c, now(), None, p, false)
─────────────────────────────────────────────────────────────────── [S-Grant]
⟨σ, Grant(s, c, p)⟩ → ⟨σ[registry(s) := σ.registry(s) ++ [g]], ()⟩
```

#### Revoke

```
          σ' = σ[registry(s) := map (λg. if g.capability = c then g[revoked := true] else g) σ.registry(s)]
────────────────────────────────────────────────────────────────────────────────────────────────────────── [S-Revoke]
⟨σ, Revoke(s, c)⟩ → ⟨σ', ()⟩
```

#### Request (Granted)

```
    σ.registry(s) ⊨ c  ∨  σ.registry("*") ⊨ c
────────────────────────────────────────────────── [S-Request-Grant]
⟨σ, Request(s, c)⟩ → ⟨σ, Ok(())⟩
```

#### Request (Denied)

```
    σ.registry(s) ⊭ c  ∧  σ.registry("*") ⊭ c
────────────────────────────────────────────────── [S-Request-Deny]
⟨σ, Request(s, c)⟩ → ⟨σ, Err(CapabilityNotGranted)⟩
```

---

## 4. Security Properties

### 4.1 No Privilege Escalation

**Theorem 4.1 (No Privilege Escalation):** A program cannot acquire capabilities beyond those explicitly granted.

**Formal Statement:** If σ₀ is the initial state and σ₀ →* σₙ via program execution (not including interactive consent), then:

```
∀s, c. σₙ.registry(s) ⊨ c → σ₀.registry(s) ⊨ c
```

**Proof:** By induction on the transition sequence. The only transitions that add capabilities are [S-Grant], which requires explicit principal authorization. Program execution (in non-interactive mode) cannot invoke Grant. □

### 4.2 Capability Confinement

**Theorem 4.2 (Confinement):** Capabilities cannot be transferred between scopes without explicit authorization.

**Formal Statement:** For distinct scopes s₁ ≠ s₂:

```
σ.registry(s₁) ⊨ c  ∧  σ.registry(s₂) ⊭ c  →
    ∀σ'. σ →* σ' → (σ'.registry(s₂) ⊨ c → Grant(s₂, c, _) occurred)
```

**Proof:** By inspection of transition rules. [S-Grant] is the only rule that adds capabilities to a scope's registry. □

### 4.3 Revocation Effectiveness

**Theorem 4.3 (Revocation):** Once revoked, a capability cannot be used until re-granted.

**Formal Statement:** If Revoke(s, c) transitions σ to σ', then:

```
∀σ''. σ' →* σ'' → (σ''.registry(s) ⊨ c → Grant(s, c, _) occurred after revocation)
```

**Proof:** [S-Revoke] sets `revoked := true` on matching grants. The validity predicate `valid(g)` checks `¬g.revoked`, so the capability is no longer satisfied. Only [S-Grant] can add new valid grants. □

### 4.4 Temporal Safety

**Theorem 4.4 (Temporal Safety):** Expired capabilities are not valid.

**Formal Statement:**

```
g.expires_at = Some(t) ∧ now() > t → ¬valid(g)
```

**Proof:** Direct from the definition of `valid(g)`. □

### 4.5 Audit Completeness

**Theorem 4.5 (Audit Completeness):** All capability operations are recorded in the audit log.

**Formal Statement:** For every transition `⟨σ, a⟩ → ⟨σ', _⟩` where a involves capabilities:

```
∃e ∈ σ'.audit_log. e.action corresponds to a
```

**Proof:** By inspection of the implementation. Each capability operation calls `self.audit()`. □

---

## 5. Information Flow Security

### 5.1 Security Labels

WokeLang's consent system can be viewed through an information flow lens:

```
L ∈ Label = {Low, High}  (simplified two-point lattice)
```

### 5.2 Consent as Declassification

A consent block `only if okay p { s }` acts as a controlled declassification:

```
               p ∈ C    Γ; C ⊢ s : τ @ L
──────────────────────────────────────────── [T-Consent-Declass]
Γ; C ⊢ only if okay p { s } : τ @ Low
```

### 5.3 Non-Interference (Relative)

**Theorem 5.1 (Relative Non-Interference):** Without consent, high-security data cannot flow to low-security outputs.

For programs P without consent blocks:

```
P(I_H, I_L) ≈_L P(I'_H, I_L)
```

Where `≈_L` means indistinguishable at low security level.

**TODO:** Full formal proof requires defining the security type system. See `verification/information-flow.v` stub.

---

## 6. Access Control Model

### 6.1 RBAC Mapping

WokeLang's scope-based capabilities map to Role-Based Access Control:

```
Role ≈ Scope (function name or "*")
Permission ≈ Capability
Subject ≈ Currently executing code
Object ≈ Protected resource
```

### 6.2 ABAC Extension

The capability system supports Attribute-Based Access Control via:
- Time-based expiry (temporal attributes)
- Path-based file access (resource attributes)
- Host-based network access (resource attributes)

### 6.3 Least Privilege

**Theorem 6.1 (Least Privilege Support):** The capability model supports least-privilege execution.

**Proof:**
1. Capabilities can be scoped to specific resources (path, command, host)
2. Capabilities can be time-limited via expiry
3. Capabilities are scope-specific (function-level granularity)
4. No implicit capability grants exist

This provides the mechanisms for least-privilege; enforcement depends on usage. □

---

## 7. Attack Resistance

### 7.1 Confused Deputy Prevention

**Theorem 7.1:** WokeLang's capability model prevents confused deputy attacks.

**Proof:**
- Capabilities are checked at the point of use, not the point of origin
- Scope-based lookup means called functions use their own capabilities, not callers'
- The consent prompt includes the requesting scope for user verification
□

### 7.2 TOCTOU Prevention

**Theorem 7.2:** The capability check-then-use is atomic.

**Proof:** The `request` method in the CapabilityRegistry performs check and grant atomically (in single-threaded context). In the current implementation, there's no TOCTOU window. □

**Note:** For concurrent execution, additional synchronization would be needed. See `concurrency/worker-safety.md`.

### 7.3 Ambient Authority Elimination

**Theorem 7.3:** WokeLang eliminates ambient authority.

**Proof:**
- All sensitive operations require explicit capability checks
- No operation succeeds based on implicit permissions
- Environment access requires Environment capability
- Process spawning requires Process capability
□

---

## 8. Formal Model in Logic

### 8.1 Authorization Logic

We can express capability properties in an authorization logic:

```
Principal says Capability @ Scope
```

For example:
```
User says FileRead("/tmp") @ main
User says Network(*) @ *
```

### 8.2 Policy Language

Capability policies can be expressed as:

```
policy ::= principal says capability @ scope [expires time]
         | revoke capability @ scope
         | if condition then policy
```

### 8.3 Policy Evaluation

```
⟦principal says c @ s⟧σ = Grant(s, c, principal)
⟦revoke c @ s⟧σ = Revoke(s, c)
⟦if e then p⟧σ = if ⟦e⟧ then ⟦p⟧σ else id
```

---

## 9. Implementation Correspondence

| Proof Concept | Implementation (`src/security/mod.rs`) |
|---------------|----------------------------------------|
| Capability | `Capability` enum |
| CapabilitySet | `capabilities: HashMap<String, Vec<GrantedCapability>>` |
| Subsumption | `capability_matches()` method |
| Grant | `grant()` method |
| Revoke | `revoke()` method |
| Request | `request()` method |
| Validity | `is_valid()` method on GrantedCapability |
| Audit | `audit()` method, `audit_log` field |

---

## 10. Known Limitations and Future Work

### 10.1 Current Limitations

1. **Single-threaded assumption:** Current proofs assume single-threaded execution
2. **Interactive consent:** Proofs don't cover user interaction dynamics
3. **Persistence:** Consent persistence (`consent.rs`) not formally verified
4. **Covert channels:** Not analyzed

### 10.2 TODO: Extensions

**TODO:** Formal verification of:
- Thread-safe capability registry
- Secure consent UI interaction
- Persistent consent store integrity
- Covert channel analysis

---

## References

1. Dennis, J.B. and Van Horn, E.C. (1966). "Programming Semantics for Multiprogrammed Computations"
2. Miller, M.S. et al. (2003). "Capability Myths Demolished"
3. Sabelfeld, A. and Myers, A.C. (2003). "Language-Based Information-Flow Security"
4. Saltzer, J.H. and Schroeder, M.D. (1975). "The Protection of Information in Computer Systems"
