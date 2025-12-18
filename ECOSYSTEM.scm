;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; ECOSYSTEM.scm — wokelang

(ecosystem
  (version "0.1.0")
  (name "wokelang")
  (type "programming-language")
  (purpose "Human-centered, consent-driven programming language")

  (position-in-ecosystem
    "WokeLang is a programming language that prioritizes consent, gratitude, and emotional context. Part of hyperpolymath ecosystem. Follows RSR guidelines.")

  (related-projects
    (project (name "rhodium-standard-repositories")
             (url "https://github.com/hyperpolymath/rhodium-standard-repositories")
             (relationship "standard"))
    (project (name "palimpsest-license")
             (url "https://github.com/hyperpolymath/palimpsest-license")
             (relationship "philosophy")))

  (what-this-is "A programming language with consent-first design, built-in gratitude attribution, emote tags for emotional context, and human-readable natural language syntax")
  (what-this-is-not "- NOT a drop-in replacement for existing languages\n- NOT designed for maximum performance\n- NOT exempt from RSR compliance"))
