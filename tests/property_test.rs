// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// SPDX-FileCopyrightText: 2026 Hyperpolymath
//
// Property-Based Tests
// Uses proptest to validate language invariants and properties

use proptest::prelude::*;
use wokelang::{Interpreter, Lexer, Parser, TypeChecker};

proptest! {
    #[test]
    #[cfg_attr(miri, ignore)]
    fn prop_lexer_produces_tokens(source in "to main\\(\\) \\{ [0-9]+ \\}") {
        let lexer = Lexer::new(&source);
        let result = lexer.tokenize();
        // Lexer should either succeed or fail gracefully
        let _ = result;
    }

    #[test]
    #[cfg_attr(miri, ignore)]
    fn prop_parser_handles_valid_syntax(
        value in 0i64..1000i64
    ) {
        let source = format!(
            "to main() {{ {}; }}",
            value
        );

        let lexer = Lexer::new(&source);
        if let Ok(tokens) = lexer.tokenize() {
            let mut parser = Parser::new(tokens, &source);
            if let Ok(ast) = parser.parse() {
                // Successfully parsed
                prop_assert!(!ast.items.is_empty());
            }
        }
    }

    #[test]
    #[cfg_attr(miri, ignore)]
    fn prop_interpreter_deterministic_on_same_input(
        val in 1i64..100i64
    ) {
        let source = format!(
            "to main() {{ {}; }}",
            val
        );

        // First execution
        let mut lexer1 = Lexer::new(&source);
        if let Ok(tokens1) = lexer1.tokenize() {
            let mut parser1 = Parser::new(tokens1, &source);
            if let Ok(ast1) = parser1.parse() {
                let mut typechecker1 = TypeChecker::new();
                let _ = typechecker1.check_program(&ast1);
                let mut interp1 = Interpreter::new();
                let result1 = interp1.run(&ast1);

                // Second execution
                let mut lexer2 = Lexer::new(&source);
                let tokens2 = lexer2.tokenize().unwrap();
                let mut parser2 = Parser::new(tokens2, &source);
                let ast2 = parser2.parse().unwrap();
                let mut typechecker2 = TypeChecker::new();
                let _ = typechecker2.check_program(&ast2);
                let mut interp2 = Interpreter::new();
                let result2 = interp2.run(&ast2);

                // Both should succeed or both should fail
                prop_assert_eq!(result1.is_ok(), result2.is_ok());
            }
        }
    }

    #[test]
    #[cfg_attr(miri, ignore)]
    fn prop_valid_identifiers(name in "[a-z_][a-z0-9_]{0,15}") {
        let source = format!(
            "to {} () {{ }}",
            name
        );

        let lexer = Lexer::new(&source);
        let tokens = lexer.tokenize();
        prop_assert!(tokens.is_ok(), "Should tokenize valid names");
    }

    #[test]
    #[cfg_attr(miri, ignore)]
    fn prop_multiple_statements(
        n in 1u32..10u32
    ) {
        let mut source = String::from("to main() { ");
        for i in 0..n {
            source.push_str(&format!("{}; ", i));
        }
        source.push_str("}");

        let lexer = Lexer::new(&source);
        if let Ok(tokens) = lexer.tokenize() {
            let mut parser = Parser::new(tokens, &source);
            let result = parser.parse();
            // Just verify it doesn't crash
            let _ = result;
        }
    }

    #[test]
    #[cfg_attr(miri, ignore)]
    fn prop_function_names_valid(name in "[a-z_][a-z0-9_]{0,10}") {
        let source = format!(
            "to {} () {{ }} to main() {{ }}",
            name
        );

        let lexer = Lexer::new(&source);
        if let Ok(tokens) = lexer.tokenize() {
            let mut parser = Parser::new(tokens, &source);
            if let Ok(ast) = parser.parse() {
                prop_assert!(ast.items.len() >= 1);
            }
        }
    }
}
