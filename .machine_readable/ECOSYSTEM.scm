;; SPDX-License-Identifier: AGPL-3.0-or-later
;; ECOSYSTEM.scm - Ecosystem position for wokelang
;; Media-Type: application/vnd.ecosystem+scm

(ecosystem
  (version "1.0")
  (name "wokelang")
  (type "programming-language")
  (purpose "Human-centered, consent-driven programming with built-in ethics")

  (position-in-ecosystem
    (category "programming-languages")
    (subcategory "domain-specific-languages")
    (unique-value
      "Consent gates for sensitive operations"
      "Built-in gratitude/attribution system"
      "Units of measure as first-class citizens"
      "Emotional annotations for code context"
      "Human-readable English-like syntax"))

  (related-projects
    (project "affinescript"
      (relationship "sibling-standard")
      (description "OCaml-based language compiler framework"))
    (project "palimpsest-licence"
      (relationship "philosophical-foundation")
      (description "Ethical licensing framework that WokeLang adopts"))
    (project "python"
      (relationship "inspiration")
      (description "Readability and accessibility influence"))
    (project "rust"
      (relationship "inspiration")
      (description "Safety-first design and performance target"))
    (project "elm"
      (relationship "inspiration")
      (description "User-friendly error messages"))
    (project "gleam"
      (relationship "inspiration")
      (description "Friendly syntax and approachability"))
    (project "roc"
      (relationship "inspiration")
      (description "Fast, friendly, functional design"))
    (project "januskey"
      (relationship "potential-consumer")
      (description "Could use WokeLang for consent-aware scripting"))
    (project "bunsenite"
      (relationship "potential-consumer")
      (description "Configuration language integration")))

  (what-this-is
    "A programming language prioritizing human collaboration and safety"
    "An ethical programming framework with consent-based control flow"
    "A tool for writing self-documenting, attribution-aware code"
    "A language with built-in dimensional analysis"
    "A practical experiment in human-centered language design")

  (what-this-is-not
    "A general-purpose systems programming language"
    "A replacement for Rust, OCaml, or production languages"
    "A toy language or joke project"
    "An AI-only or machine-generated language"
    "A language focused on maximum performance"))