;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2026 Hyperpolymath
;;
;; Machine-readable roadmap for WokeLang
;; f0 = foundation milestone (initial machine-readable spec)

(define roadmap
  '((schema . "hyperpolymath.roadmap/1")
    (repo . "hyperpolymath/wokelang")
    (version . "f0")
    (last-updated . "2026-01-01")

    (current-milestone
      . ((name . "foundation")
         (version . "0.1.x")
         (status . "complete")
         (features
           . ((grammar . "complete")
              (lexer . "complete")
              (parser . "complete")
              (ast . "complete")
              (interpreter . "complete")
              (cli . "complete")
              (repl . "complete")
              (wasm-basic . "complete")
              (c-ffi . "complete")
              (zig-ffi . "complete")))))

    (milestones
      . (((id . "m1")
          (name . "language-completeness")
          (target . "0.2.0")
          (dependencies . ())
          (features
            . ((static-type-inference . "planned")
               (generic-types . "planned")
               (union-types . "planned")
               (pattern-matching . "planned")
               (module-system . "planned")
               (result-types . "planned")
               (error-propagation . "planned"))))

         ((id . "m2")
          (name . "concurrency-safety")
          (target . "0.3.0")
          (dependencies . ("m1"))
          (features
            . ((async-workers . "planned")
               (message-passing . "planned")
               (worker-pools . "planned")
               (side-quests . "planned")
               (capability-security . "planned")
               (consent-persistence . "planned"))))

         ((id . "m3")
          (name . "standard-library")
          (target . "0.4.0")
          (dependencies . ("m2"))
          (features
            . ((std-io . "planned")
               (std-net . "planned")
               (std-json . "planned")
               (std-time . "planned")
               (std-math . "planned")
               (std-units . "planned")
               (consent-aware-modules . "planned"))))

         ((id . "m4")
          (name . "optimizing-compiler")
          (target . "0.5.0")
          (dependencies . ("m3"))
          (features
            . ((wasm-full . "planned")
               (wasi-integration . "planned")
               (llvm-backend . "planned")
               (native-binaries . "planned")
               (optimizations . "planned"))))

         ((id . "m5")
          (name . "tooling-ecosystem")
          (target . "0.6.0-0.7.0")
          (dependencies . ("m4"))
          (features
            . ((vscode-extension . "planned")
               (lsp-server . "planned")
               (tree-sitter . "planned")
               (package-manager . "planned")
               (test-framework . "planned")
               (doc-generator . "planned"))))

         ((id . "m6")
          (name . "stable-release")
          (target . "1.0.0")
          (dependencies . ("m5"))
          (features
            . ((api-stability . "planned")
               (semantic-versioning . "planned")
               (migration-guides . "planned")
               (lts-support . "planned"))))))

    (completed-work
      . ((grammar
           . ((file . "docs/grammar.ebnf")
              (status . "canonical")))
         (proofs
           . ((directory . "docs/proofs/")
              (lean . "docs/proofs/verification/WokeLang.lean")
              (coq . "docs/proofs/verification/WokeLang.v")
              (status . "foundational")))
         (examples
           . ((directory . "examples/")
              (count . 10)
              (coverage . "basic-features")))))

    (blocking-issues . ())

    (downstream-impact
      . ((wokelang-playground
           . "Depends on stable grammar and error message format")
         (wokelang-vscode
           . "Depends on LSP implementation (m5)")
         (wokelang-lsp
           . "Depends on incremental parsing (m5)")))))
