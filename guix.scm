; SPDX-License-Identifier: MPL-2.0
;; guix.scm — GNU Guix package definition for wokelang
;; Usage: guix shell -f guix.scm

(use-modules (guix packages)
             (guix build-system gnu)
             (guix licenses))

(package
  (name "wokelang")
  (version "0.1.0")
  (source #f)
  (build-system gnu-build-system)
  (synopsis "A human-centred, consent-driven programming language")
  (description
   "WokeLang is a statically typed programming language whose type system
discharges consent and affine-use reasoning, so destructive operations are
scaffolded at the language level rather than by convention.  The primary
toolchain is written in Rust; a smaller OCaml reference core cross-checks the
semantics.")
  (home-page "https://github.com/hyperpolymath/wokelang")
  ;; Code is MPL-2.0 (documentation is CC-BY-SA-4.0, see LICENSES/).
  ;;
  ;; This previously read:
  ;;   (license ((@@ (guix licenses) license) "MPL-2.0" "…"))
  ;; which was broken two ways: `@@` reaches into a NON-EXPORTED binding of
  ;; (guix licenses), and the `license` record constructor takes three fields
  ;; (name uri comment) but was given two. Since guix is not installed on the
  ;; development host, nothing ever evaluated this file and the fault went
  ;; unnoticed. `mpl2.0` is exported by (guix licenses) and is the correct
  ;; spelling.
  (license mpl2.0))
