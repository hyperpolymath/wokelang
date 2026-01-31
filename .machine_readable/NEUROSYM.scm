;; SPDX-License-Identifier: PMPL-1.0-or-later
;; NEUROSYM.scm - Neurosymbolic integration config for wokelang

(define neurosym-config
  \`((version . "1.0.0")
    (symbolic-layer
      ((type . "scheme")
       (reasoning . "deductive")
       (verification . "formal")
       (grammar . "EBNF in docs/grammar.ebnf")
       (type-system . "hindley-milner-inspired")))
    (neural-layer
      ((embeddings . false)
       (fine-tuning . false)
       (llm-integration
         (code-generation . "claude-opus-4-5")
         (code-review . "claude-opus-4-5")
         (documentation . "claude-opus-4-5"))))
    (integration
      ((consent-validation
         (approach . "symbolic-first")
         (description . "Consent gates are checked symbolically at compile time"))
       (unit-checking
         (approach . "symbolic")
         (description . "Dimensional analysis via type system"))
       (error-messages
         (approach . "neural-enhanced")
         (description . "LLM can suggest fixes for common errors"))
       (documentation-gen
         (approach . "neural")
         (description . "Generate docs from code using LLM"))))))
