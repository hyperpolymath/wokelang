;; SPDX-License-Identifier: AGPL-3.0-or-later
;; AGENTIC.scm - AI agent interaction patterns for wokelang

(define agentic-config
  \`((version . "1.0.0")
    (claude-code
      ((model . "claude-opus-4-5-20251101")
       (tools . ("read" "edit" "bash" "grep" "glob"))
       (permissions . "read-all")))
    (patterns
      ((code-review
         (style . "thorough")
         (focus . ("consent-safety" "human-readability" "unit-correctness")))
       (refactoring
         (style . "conservative")
         (preserve . ("consent-gates" "gratitude-blocks" "emote-annotations")))
       (testing
         (style . "comprehensive")
         (coverage . ("parser" "interpreter" "consent-system")))))
    (language-specific
      ((syntax-patterns
         (function-def . "to NAME(PARAMS) { ... }")
         (variable . "remember NAME = VALUE")
         (conditional . "when COND { ... } otherwise { ... }")
         (loop . "repeat N times { ... }")
         (consent . "only if okay MESSAGE { ... }")
         (gratitude . "thanks to { CONTRIBUTOR -> CONTRIBUTION }")
         (units . "VALUE measured in UNIT")
         (emote . "@feeling(param=value) STATEMENT"))
       (error-handling
         (try-block . "attempt safely { ... } or reassure MESSAGE")
         (error-throw . "complain MESSAGE"))
       (concurrency
         (worker . "worker NAME { ... }")
         (spawn . "spawn worker NAME")
         (message . "send VALUE to TARGET"))))
    (constraints
      ((languages . ("rust" "ocaml" "wasm"))
       (banned . ("typescript" "go" "python" "makefile"))
       (preferred-tools
         (build . "just")
         (format-rust . "cargo fmt")
         (format-ocaml . "ocamlformat")
         (lint-rust . "cargo clippy"))))))
