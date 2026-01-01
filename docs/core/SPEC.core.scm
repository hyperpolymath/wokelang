;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2026 Hyperpolymath

;; WokeLang Core Semantics Specification
;; Defines consent gates and units of measure semantics

(define wokelang-core-spec
  '((version . "0.1.0")
    (status . "draft")

    ;; ===========================================
    ;; Consent Gate Semantics
    ;; ===========================================

    (consent-gates
      . ((description . "Consent gates provide explicit, auditable permission for sensitive operations")

         (syntax . "only if okay <permission-string> { <body> }")

         (semantics
           . ((evaluation-order . "permission-string evaluated first, then body if granted")
              (consent-check . "implementation-defined; must be explicit and testable")
              (body-execution . "only if consent granted")
              (scope . "consent valid only within block")
              (nesting . "inner consent blocks require separate grants")))

         (properties
           . ((explicit . "consent must be explicitly requested")
              (auditable . "all consent requests must be loggable")
              (testable . "consent can be mocked for testing")
              (revocable . "consent can be withdrawn")
              (scoped . "consent does not leak across boundaries")))

         (io-policy
           . ((prompts . "must be explicit, not hidden")
              (defaults . "no implicit consent; default is deny")
              (persistence . "implementation-defined; may cache for session")))))

    ;; ===========================================
    ;; Units of Measure Semantics
    ;; ===========================================

    (units-of-measure
      . ((description . "Units of measure prevent dimensional errors at runtime")

         (syntax . "<expr> measured in <unit>")

         (semantics
           . ((declaration . "attaches unit to value")
              (propagation . "units propagate through arithmetic")
              (compatibility . "operations require compatible units")
              (mismatch . "unit mismatch is a runtime error")))

         (operations
           . ((addition . "same units required; result has same unit")
              (subtraction . "same units required; result has same unit")
              (multiplication . "units combine (future: derived units)")
              (division . "units cancel or combine (future: derived units)")
              (comparison . "same units required")))

         (error-handling
           . ((mismatch-error . "deterministic error with unit names")
              (message-format . "Unit mismatch: <unit1> vs <unit2>")))))

    ;; ===========================================
    ;; Gratitude Semantics
    ;; ===========================================

    (gratitude
      . ((description . "Gratitude blocks acknowledge contributors in code")

         (syntax . "thanks to { <contributor> → <contribution>; ... }")

         (semantics
           . ((evaluation . "processed at program load time")
              (storage . "implementation maintains gratitude registry")
              (visibility . "gratitude entries are loggable/queryable")))

         (properties
           . ((attribution . "provides formal code attribution")
              (auditable . "gratitude trail is auditable")
              (non-blocking . "does not affect control flow")))))

    ;; ===========================================
    ;; Error Handling Semantics
    ;; ===========================================

    (error-handling
      . ((description . "Safe error handling with reassurance")

         (syntax . "attempt safely { <body> } or reassure <message>")

         (semantics
           . ((try-body . "execute body statements")
              (on-error . "print reassurance message, continue")
              (error-recovery . "errors in body are caught")))

         (properties
           . ((graceful . "errors are handled gracefully")
              (informative . "reassurance provides context")
              (non-panicking . "program does not crash")))))

    ;; ===========================================
    ;; Deterministic Diagnostics
    ;; ===========================================

    (diagnostics
      . ((description . "All error messages must be deterministic and helpful")

         (requirements
           . ((determinism . "same input always produces same error")
              (location . "line and column information when available")
              (context . "relevant context in error message")
              (suggestion . "helpful suggestions when possible")))

         (categories
           . ((lexical . "unexpected character, unterminated string/comment")
              (syntactic . "unexpected token, missing delimiter")
              (semantic . "type mismatch, undefined variable")
              (runtime . "division by zero, unit mismatch")))))))

;; End of specification
