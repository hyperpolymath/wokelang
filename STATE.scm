;; SPDX-License-Identifier: PMPL-1.0
;; STATE.scm - Project state for wokelang

(state
  (metadata
    (version "0.1.0")
    (schema-version "1.0")
    (created "2024-06-01")
    (updated "2025-01-17")
    (project "wokelang")
    (repo "hyperpolymath/wokelang"))

  (project-context
    (name "WokeLang")
    (tagline "Human-centered programming language for collaboration, empathy, and safety")
    (tech-stack ("ocaml" "rust" "vyper")))

  (current-position
    (phase "specification")
    (overall-completion 15)
    (working-features
      ("Language specification"
       "OCaml parser prototype"
       "Rust runtime design"))))
