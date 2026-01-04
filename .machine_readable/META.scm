;; SPDX-License-Identifier: AGPL-3.0-or-later
;; META.scm - Meta-level information for wokelang
;; Media-Type: application/meta+scheme

(meta
  (architecture-decisions
    (adr-001
      (title "Dual Implementation Strategy")
      (status "accepted")
      (date "2024-10")
      (context "Need both rapid prototyping and production performance")
      (decision "Use OCaml for language theory, Rust for production runtime")
      (consequences
        "Faster iteration on language design"
        "Production-grade performance"
        "Requires maintaining two codebases"))
    (adr-002
      (title "Consent-First Design")
      (status "accepted")
      (date "2024-10")
      (context "Sensitive operations should require explicit permission")
      (decision "Implement 'only if okay' gates for sensitive operations")
      (consequences
        "Safer by default"
        "Self-documenting dangerous code paths"
        "Slight increase in verbosity"))
    (adr-003
      (title "Human-Readable Syntax")
      (status "accepted")
      (date "2024-10")
      (context "Code should be readable by non-programmers")
      (decision "Use English-like keywords: to, give back, remember, when")
      (consequences
        "Lower barrier to entry"
        "More inclusive programming"
        "Slightly longer code"))
    (adr-004
      (title "Units of Measure as First-Class")
      (status "accepted")
      (date "2024-11")
      (context "Unit-related bugs are common and dangerous")
      (decision "Add 'measured in' syntax for compile-time unit checking")
      (consequences
        "Prevents NASA-style unit bugs"
        "Self-documenting calculations"
        "Requires dimensional analysis system")))

  (development-practices
    (code-style
      (rust "cargo fmt and clippy")
      (ocaml "ocamlformat")
      (documentation "AsciiDoc preferred"))
    (security
      (principle "Defense in depth")
      (consent-model "Explicit opt-in for sensitive operations")
      (capability-system "Fine-grained permission control"))
    (testing
      (unit "Per-component tests in tests/")
      (integration "End-to-end language tests")
      (fuzzing "Property-based testing for parser"))
    (versioning "SemVer")
    (documentation "AsciiDoc for docs, docstrings for code")
    (branching "main for stable, feature branches for development"))

  (design-rationale
    (why-consent-gates
      "Sensitive operations like file I/O, network access, and data deletion "
      "should require explicit permission. This prevents accidental damage "
      "and makes dangerous code paths visible.")
    (why-gratitude-blocks
      "Attribution is often lost in codebases. The 'thanks to' syntax makes "
      "it easy to acknowledge contributors inline where their work is used.")
    (why-emote-annotations
      "Code carries emotional context. A fix made under pressure differs from "
      "one made thoughtfully. @emote tags capture this for future readers.")
    (why-units-of-measure
      "The Mars Climate Orbiter was lost due to a unit conversion error. "
      "Compile-time dimensional analysis prevents these catastrophic bugs.")))