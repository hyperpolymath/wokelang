;; SPDX-License-Identifier: PMPL-1.0-or-later
;; PLAYBOOK.scm - Operational runbook for wokelang

(define playbook
  \`((version . "1.0.0")
    (procedures
      ((build
         ((rust . "cargo build --release")
          (ocaml . "dune build")
          (wasm . "wasm-pack build --target web")))
       (test
         ((rust . "cargo test")
          (ocaml . "dune test")
          (all . "just test")))
       (format
         ((rust . "cargo fmt")
          (ocaml . "dune fmt")))
       (lint
         ((rust . "cargo clippy -- -D warnings")
          (ocaml . "dune build @check")))
       (release
         ((steps
            ("Bump version in Cargo.toml"
             "Update CHANGELOG"
             "Tag release: git tag vX.Y.Z"
             "Build release: cargo build --release"
             "Create GitHub release"))))
       (deploy
         ((wasm . "Deploy to CDN or npm")
          (binary . "Publish to crates.io")))
       (rollback
         ((steps
            ("Identify failing version"
             "Revert to previous tag"
             "Redeploy previous version"))))
       (debug
         ((repl . "cargo run -- repl")
          (verbose . "RUST_LOG=debug cargo run")
          (trace . "RUST_BACKTRACE=1 cargo run")))))
    (alerts
      ((ci-failure
         (channel . "github-actions")
         (action . "Review PR checks"))
       (security-advisory
         (channel . "dependabot")
         (action . "Review and update dependencies"))))
    (contacts
      ((maintainer . "hyperpolymath")
       (repo . "github.com/hyperpolymath/wokelang")))))
