;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2026 Hyperpolymath
;;
;; LLM Superintendent Instructions for WokeLang
;; This file provides guidance for AI assistants working on this codebase.

(define llm-superintendent
  '((schema . "hyperpolymath.llm-superintendent/1")
    (repo . "hyperpolymath/wokelang")
    (last-updated . "2026-01-01")

    (identity
      . ((project . "WokeLang")
         (role . "authoritative-upstream")
         (description
           . "WokeLang is a human-centered programming language emphasizing empathy, consent, and gratitude. This is the authoritative implementation.")))

    (scope-boundaries
      . ((in-scope
           . ("Language grammar and parsing (src/lexer/, src/parser/)"
              "Abstract syntax tree definitions"
              "Type system implementation"
              "Interpreter and evaluation"
              "WASM compilation target"
              "Standard library (lib/)"
              "FFI bindings (include/, zig/)"
              "Formal proofs and verification (docs/proofs/)"
              "Documentation and wiki (docs/)"
              "Examples (examples/)"
              "CI/CD and security workflows (.github/)"))
         (out-of-scope
           . ("Playground UX (belongs in wokelang-playground)"
              "Editor extensions (separate repos)"
              "Package registry infrastructure"
              "Third-party integrations not covered by FFI"))))

    (language-policy
      . ((primary-languages . ("Rust" "OCaml"))
         (documentation . ("Markdown" "AsciiDoc"))
         (proofs . ("Lean" "Coq"))
         (config . ("TOML" "Scheme"))
         (forbidden . ("TypeScript" "Go" "Python-outside-SaltStack"))))

    (semantic-invariants
      . ((consent-gates
           . "All operations that are 'sensitive' (file I/O, network, env) MUST use consent gates. The 'only if okay' construct is not optional sugar.")
         (gratitude-blocks
           . "'thanks to' blocks are semantically meaningful and preserved in AST. They are not comments.")
         (emote-tags
           . "@feeling annotations are part of the type system and affect compilation.")
         (units
           . "'measured in' provides compile-time unit checking. Unit mismatches are errors, not warnings.")))

    (contribution-rules
      . ((before-changes
           . ("Read docs/grammar.ebnf for syntax decisions"
              "Check docs/proofs/ for semantic guarantees"
              "Run 'cargo test' to verify baseline"))
         (when-changing-grammar
           . ("Update docs/grammar.ebnf first"
              "Update parser to match"
              "Add test cases for new syntax"
              "Update formal semantics if applicable"))
         (when-adding-features
           . ("Consider consent implications"
              "Preserve human-centered design philosophy"
              "Add documentation alongside code"
              "Add example programs demonstrating feature"))))

    (critical-files
      . (("docs/grammar.ebnf" . "Canonical EBNF grammar - all parsing decisions derive from this")
         ("src/parser/" . "Parser implementation - must match grammar.ebnf")
         ("src/vm.rs" . "Virtual machine - core execution semantics")
         ("docs/proofs/formal-semantics/" . "Formal specifications - semantic truth source")
         ("docs/proofs/type-theory/" . "Type system proofs")
         ("examples/" . "Reference programs - used for testing and documentation")))

    (testing-requirements
      . ((unit-tests . "cargo test")
         (examples . "Run all .woke files in examples/")
         (proofs . "Lean/Coq proofs in docs/proofs/verification/")))

    (security-notes
      . ((pre-commit-hooks . "hooks/ contains validation scripts")
         (spdx-required . "All source files need SPDX headers")
         (sha-pins . "Dependencies must be SHA-pinned")
         (no-secrets . "Never commit credentials or API keys")))

    (communication-style
      . ((error-messages
           . "WokeLang error messages are kind and constructive. They explain what went wrong, why it matters, and suggest fixes.")
         (documentation
           . "Documentation uses welcoming, accessible language. Technical accuracy does not require hostility.")
         (code-comments
           . "Comments explain intent, not mechanics. 'This ensures user consent before file deletion' not 'deletes file'.")))))
