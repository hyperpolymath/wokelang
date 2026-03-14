;; SPDX-License-Identifier: PMPL-1.0-or-later
;; ECOSYSTEM.scm for wokelang
;; Media Type: application/vnd.ecosystem+scm

(ecosystem
  (version "1.0")
  (name "wokelang")
  (type "programming-language")
  (purpose "Experimental programming language exploring social-awareness in language design")

  (position-in-ecosystem
    (domain "programming-languages")
    (role "Experimental language within the nextgen-languages monorepo")
    (maturity "concept"))

  (related-projects
    ((name . "nextgen-languages")
     (relationship . part-of)
     (nature . "Monorepo for experimental language projects"))))
