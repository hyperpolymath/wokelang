; SPDX-License-Identifier: AGPL-3.0-or-later
; SPDX-FileCopyrightText: 2026 Hyperpolymath

(lang dune 3.0)
(name wokelang)
(version 0.1.0)

(generate_opam_files true)

(source (github hyperpolymath/wokelang))
(license AGPL-3.0-or-later)
(authors "Hyperpolymath")
(maintainers "hyperpolymath@example.com")

(package
 (name wokelang)
 (synopsis "A human-centered, consent-driven programming language")
 (description
   "WokeLang is a programming language designed for human collaboration,
    empathy, and safety. It features consent gates, gratitude blocks,
    units of measure, and emotionally-aware annotations.")
 (depends
  (ocaml (>= 5.0))
  (dune (>= 3.0))
  (menhir (>= 20230608))))
