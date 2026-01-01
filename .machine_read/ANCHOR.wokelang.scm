;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2026 Hyperpolymath
;;
;; Machine-readable anchor for WokeLang
;; Schema: hyperpolymath.anchor/1

(define anchor
  '((schema . "hyperpolymath.anchor/1")
    (repo . "hyperpolymath/wokelang")
    (date . "2026-01-01")
    (authority . "repo-superintendent")
    (purpose
      . ("Authoritative source for WokeLang language specification."
         "Human-centered programming language: empathy, consent, and gratitude as first-class concepts."
         "All downstream implementations defer to this repo for semantics and grammar."))

    (identity
      . ((project . "WokeLang")
         (kind . "language-core")
         (one-sentence . "A human-centered programming language with empathy, consent, and gratitude.")
         (upstream . #f)))  ; This IS the upstream

    (semantic-anchor
      . ((policy . "authoritative")
         (downstream-repos
           . ("hyperpolymath/wokelang-playground"
              "hyperpolymath/wokelang-vscode"
              "hyperpolymath/wokelang-lsp"))
         (authority-scope
           . ("EBNF grammar specification (docs/grammar.ebnf)"
              "Language semantics and type system"
              "Compiler implementation (src/)"
              "Standard library definitions"
              "Consent system semantics"
              "Gratitude block semantics"
              "Emote tag semantics"))))

    (implementation-policy
      . ((allowed . ("Rust" "OCaml" "Scheme" "Shell" "Just" "Markdown" "AsciiDoc" "Lean" "Coq"))
         (primary . ("Rust" "OCaml"))
         (quarantined . ("JavaScript without ReScript" "TypeScript"))
         (forbidden
           . ("Competing language specification"
              "Breaking semantic changes without RFC"
              "Removal of consent gates"
              "Removal of gratitude blocks"))))

    (golden-path
      . ((smoke-test-command
           . ("cargo test"
              "cargo run -- examples/hello.woke"
              "cargo run -- repl"))
         (success-criteria
           . ("All core tests pass."
              "REPL evaluates basic expressions."
              "Example programs run without error."
              "WASM compilation produces valid modules."))))

    (mandatory-files
      . ("./.machine_read/LLM_SUPERINTENDENT.scm"
         "./.machine_read/ROADMAP.f0.scm"
         "./.machine_read/SPEC.core.scm"
         "./.machine_read/AUTHORITY_STACK.mustfile-nickel.scm"))

    (first-pass-directives
      . ("Ensure grammar.ebnf is canonical."
         "Verify all semantic constructs documented in proofs/."
         "Validate consent/gratitude/emote semantics are formally specified."))

    (rsr . ((target-tier . "silver-now")
            (current-achievements
              . ("EBNF grammar specification"
                 "Tree-walking interpreter"
                 "WASM compilation"
                 "Formal proofs (Lean, Coq)"
                 "Security validation hooks"))
            (upgrade-path . "gold-after-v0.3 (full type system + native compilation)")))))
