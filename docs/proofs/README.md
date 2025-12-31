# WokeLang Formal Proofs and Academic Documentation

This directory contains formal mathematical proofs, specifications, and academic documentation for the WokeLang programming language.

## Directory Structure

```
proofs/
├── formal-semantics/     # Operational and denotational semantics
├── type-theory/          # Type system proofs and foundations
├── security/             # Capability-based security proofs
├── compiler/             # Compiler correctness proofs
├── complexity/           # Complexity analysis
├── concurrency/          # Worker system and concurrency proofs
├── verification/         # Formal verification specifications (Coq/Lean)
└── papers/               # White papers and design documents
```

## Quick Reference

| Document | Status | Description |
|----------|--------|-------------|
| [Operational Semantics](formal-semantics/operational-semantics.md) | Complete | Big-step and small-step semantics |
| [Denotational Semantics](formal-semantics/denotational-semantics.md) | Complete | Mathematical meaning of programs |
| [Type Safety](type-theory/type-safety.md) | Complete | Progress and preservation theorems |
| [Hindley-Milner](type-theory/hindley-milner.md) | Complete | Type inference algorithm |
| [Capability Security](security/capability-proofs.md) | Complete | Security properties |
| [Consent Model](security/consent-model.md) | Complete | Formal consent semantics |
| [Compiler Correctness](compiler/semantic-preservation.md) | Complete | Correctness of compilation |
| [Complexity](complexity/complexity-analysis.md) | Complete | Time and space bounds |
| [Concurrency](concurrency/worker-safety.md) | Complete | Worker system proofs |
| [Coq Specification](verification/WokeLang.v) | Stub | Formal verification in Coq |
| [Language Design](papers/language-design-whitepaper.md) | Complete | Design rationale |

## Mathematical Notation

Throughout these documents, we use standard notation:

- `Γ` (Gamma): Type environment
- `⊢` (turnstile): Type judgment
- `→` (arrow): Function type / reduction
- `⇓` (double arrow): Big-step evaluation
- `⊆` (subset): Subtyping / capability subsumption
- `∀` (forall): Universal quantification
- `∃` (exists): Existential quantification
- `⊥` (bottom): Error / undefined
- `⊤` (top): Unit / any type

## Citation

If using these proofs in academic work:

```bibtex
@misc{wokelang2025,
  title={WokeLang: A Consent-Driven, Human-Centered Programming Language},
  author={WokeLang Contributors},
  year={2025},
  howpublished={\url{https://github.com/hyperpolymath/wokelang}}
}
```

## License

This documentation is released under the same license as WokeLang (see repository root).
