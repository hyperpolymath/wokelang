;; SPDX-License-Identifier: AGPL-3.0-or-later
;; STATE.scm - Project state for wokelang
;; Media-Type: application/vnd.state+scm

(state
  (metadata
    (version "0.1.0")
    (schema-version "1.0")
    (created "2026-01-03")
    (updated "2026-01-04")
    (project "wokelang")
    (repo "github.com/hyperpolymath/wokelang"))

  (project-context
    (name "wokelang")
    (tagline "A human-centered, consent-driven programming language")
    (tech-stack
      ("Rust" "Primary implementation")
      ("OCaml" "Core language theory")
      ("WASM" "Browser/portable target")))

  (current-position
    (phase "foundation-complete")
    (overall-completion 25)
    (components
      (lexer (status "complete") (completion 100))
      (parser (status "complete") (completion 100))
      (ast (status "complete") (completion 100))
      (interpreter (status "complete") (completion 100))
      (repl (status "complete") (completion 100))
      (vm (status "in-progress") (completion 40))
      (typechecker (status "planned") (completion 10))
      (stdlib (status "in-progress") (completion 30))
      (security (status "in-progress") (completion 50)))
    (working-features
      "to/give back functions"
      "remember variables"
      "when/otherwise conditionals"
      "repeat...times loops"
      "only if okay consent gates"
      "thanks to gratitude blocks"
      "measured in units"
      "@emote annotations"))

  (route-to-mvp
    (milestones
      (phase-2 "Language Completeness" (target "Q1 2026"))
      (phase-3 "Concurrency & Safety" (target "Q2 2026"))
      (phase-4 "Standard Library" (target "Q3 2026"))
      (phase-5 "Compiler & Performance" (target "Q4 2026"))))

  (blockers-and-issues
    (high "Type system design not finalized")
    (medium "Worker implementation incomplete"))

  (critical-next-actions
    (immediate "Complete bytecode VM" "Add unit tests")
    (this-week "Implement type inference")
    (this-month "Complete Phase 2"))

  (session-history
    (session "2026-01-04" "Updated SCM files")))