;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2026 Hyperpolymath
;;
;; Core Language Specification Contract for WokeLang
;; This file defines the semantic invariants that all implementations must preserve.

(define spec-core
  '((schema . "hyperpolymath.spec/1")
    (repo . "hyperpolymath/wokelang")
    (spec-version . "0.1.0")
    (last-updated . "2026-01-01")

    (identity
      . ((language . "WokeLang")
         (paradigms . ("functional" "imperative" "consent-driven"))
         (philosophy . "Human-centered programming with empathy, consent, and gratitude.")))

    ;; Core language constructs and their semantics
    (constructs
      . (;; Functions
         ((name . "function-definition")
          (syntax . "to <name>(<params>) -> <body>")
          (keyword . "to")
          (return-keyword . "give back")
          (semantics . "Defines a callable function. Return is optional; last expression is implicit return."))

         ;; Variables
         ((name . "variable-binding")
          (syntax . "remember <name> = <value>")
          (keyword . "remember")
          (semantics . "Creates an immutable binding. Shadowing is allowed in nested scopes."))

         ((name . "mutable-binding")
          (syntax . "remember <name> = <value> (can change)")
          (keyword . "remember")
          (modifier . "can change")
          (semantics . "Creates a mutable binding. Mutation requires explicit consent."))

         ;; Conditionals
         ((name . "conditional")
          (syntax . "when <condition> { <body> } otherwise { <body> }")
          (keywords . ("when" "otherwise"))
          (semantics . "Evaluates condition, executes corresponding branch."))

         ;; Loops
         ((name . "counted-loop")
          (syntax . "repeat <n> times { <body> }")
          (keywords . ("repeat" "times"))
          (semantics . "Executes body n times. Loop variable is optional."))

         ((name . "collection-loop")
          (syntax . "for each <item> in <collection> { <body> }")
          (keywords . ("for" "each" "in"))
          (semantics . "Iterates over collection, binding each element to item."))

         ;; Pattern Matching
         ((name . "pattern-match")
          (syntax . "decide based on <value> { is <pattern> -> <body> }")
          (keywords . ("decide" "based" "on" "is"))
          (semantics . "Matches value against patterns, executes first matching branch."))

         ;; Pipeline
         ((name . "pipeline")
          (syntax . "<value> then <function> then <function>")
          (keyword . "then")
          (semantics . "Left-to-right function composition. Each step receives previous result."))))

    ;; Consent System - CRITICAL SEMANTIC
    (consent-system
      . ((purpose . "Ensure explicit user consent for sensitive operations.")
         (constructs
           . (((name . "consent-gate")
               (syntax . "only if okay \"<prompt>\" { <body> }")
               (keywords . ("only" "if" "okay"))
               (semantics
                 . ("Displays prompt to user."
                    "Waits for explicit confirmation."
                    "Executes body ONLY if consent granted."
                    "Provides safe alternative path if denied."))
               (invariants
                 . ("Consent MUST be obtained before execution."
                    "Consent is not assumable or cacheable without explicit opt-in."
                    "Denial MUST NOT cause program crash."
                    "Prompt text MUST be honest about what will happen.")))))
         (sensitive-operations
           . ("file-system-write"
              "file-system-delete"
              "network-request"
              "environment-access"
              "process-spawn"
              "database-write"
              "external-service-call"))))

    ;; Gratitude System
    (gratitude-system
      . ((purpose . "Acknowledge contributions and dependencies in code.")
         (constructs
           . (((name . "gratitude-block")
               (syntax . "thanks to { \"<contributor>\" -> \"<contribution>\" }")
               (keyword . "thanks to")
               (semantics
                 . ("Semantically meaningful acknowledgment."
                    "Preserved in AST and metadata."
                    "Extractable for attribution reports."
                    "NOT a comment - has semantic weight."))
               (invariants
                 . ("Gratitude blocks MUST be preserved in compilation."
                    "Removal of gratitude is a semantic change."
                    "Gratitude metadata MUST be accessible at runtime.")))))
         (use-cases
           . ("Acknowledging code contributors"
              "Crediting library authors"
              "Documenting inspiration sources"
              "License attribution"))))

    ;; Emote System
    (emote-system
      . ((purpose . "Capture emotional context and intent in code.")
         (constructs
           . (((name . "emote-annotation")
               (syntax . "@feeling(<attributes>)")
               (keyword . "@feeling")
               (attributes . ("confident" "uncertain" "experimental" "stable" "concerned"))
               (semantics
                 . ("Annotations are part of type system."
                    "Can affect compilation warnings/errors."
                    "Preserved in documentation generation."
                    "Enables emotional context in code review.")))))
         (compiler-effects
           . (("@feeling(uncertain=true)" . "Generates advisory warning")
              ("@feeling(experimental=true)" . "Marks API as unstable")
              ("@feeling(concerned=true)" . "Triggers additional static analysis")))))

    ;; Units System
    (units-system
      . ((purpose . "Compile-time dimensional analysis to prevent unit errors.")
         (constructs
           . (((name . "unit-annotation")
               (syntax . "<value> measured in <unit>")
               (keywords . ("measured" "in"))
               (semantics
                 . ("Compile-time unit checking."
                    "Unit mismatches are ERRORS, not warnings."
                    "Automatic unit conversion where safe."
                    "Preserves dimensional correctness.")))))
         (built-in-units
           . ("length" "time" "mass" "temperature" "currency" "data-size"))
         (invariants
           . ("Adding values with incompatible units is a compile error."
              "Unit information is preserved through calculations."
              "Explicit conversion required for incompatible types."))))

    ;; Error Handling Philosophy
    (error-philosophy
      . ((principle . "Errors should be kind, constructive, and helpful.")
         (requirements
           . ("Error messages explain what went wrong."
              "Error messages explain why it matters."
              "Error messages suggest how to fix the issue."
              "Error messages never blame the programmer."
              "Error messages use accessible, welcoming language."))
         (result-types
           . ((ok-type . "Okay[T]")
              (error-type . "Oops[E]")
              (propagation . "? operator for early return")))
         (example-error
           . ("Bad: 'Type error: expected Int, got String'"
              "Good: 'I found a text value where I expected a number. In line 5, you're adding \"hello\" to 42. Numbers and text don't mix in addition. Try converting the text to a number first with parseNumber(\"hello\"), or check if you meant to use a different variable.'"))))

    ;; Type System
    (type-system
      . ((style . "hindley-milner-inspired")
         (inference . "full-type-inference")
         (built-in-types
           . ("Int" "Float" "String" "Bool" "Array[T]" "Record" "Function" "Unit"))
         (special-types
           . ("Okay[T]" "Oops[E]" "Worker[T]" "Consent[T]"))
         (invariants
           . ("No implicit type coercion except numeric widening."
              "Unit annotations are part of type."
              "Consent gates introduce Consent[T] wrapper."))))

    ;; Determinism Requirements
    (determinism
      . ((pure-functions . "Functions without side effects are referentially transparent.")
         (side-effects . "Side effects require consent gates or are explicitly marked.")
         (testing . "All examples must produce deterministic output for snapshot testing.")))

    ;; Downstream Contracts
    (downstream-contracts
      . ((playground
           . ((error-format . "Errors must be parseable for UI display.")
              (exit-codes . "0 = success, 1 = runtime error, 2 = parse error, 3 = type error")
              (stdout . "Normal output goes to stdout.")
              (stderr . "Errors and diagnostics go to stderr.")))
         (lsp
           . ((incremental-parsing . "Parser must support partial re-parsing.")
              (position-mapping . "AST nodes track source positions.")
              (error-recovery . "Parser continues after errors where possible.")))))))
