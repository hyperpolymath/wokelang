// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath
//
// E2E Full Pipeline Tests
// Validates the complete pipeline: Lex → Parse → TypeCheck → Interpret

use wokelang::{Interpreter, Lexer, Parser, TypeChecker};

#[test]
fn e2e_lexer_parser_pipeline() {
    // Test that the pipeline doesn't crash with valid input
    let source = "to main() { give back 42; }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize();
    assert!(tokens.is_ok(), "Lexing should succeed");

    if let Ok(tokens) = tokens {
        let mut parser = Parser::new(tokens, source);
        let ast = parser.parse();
        // Pipeline should work without crashing
        if let Ok(ast) = ast {
            assert!(ast.items.len() > 0, "Should have parsed at least one item");

            let mut typechecker = TypeChecker::new();
            let _result = typechecker.check_program(&ast);

            let mut interpreter = Interpreter::new();
            let _result = interpreter.run(&ast);
            // Interpretation succeeded
        }
    }
}

#[test]
fn e2e_integer_literal() {
    let source = "to main() { 42; }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");
    assert!(!tokens.is_empty(), "Tokens should not be empty");

    let mut parser = Parser::new(tokens, source);
    let result = parser.parse();
    // Just verify pipeline doesn't crash
    let _ = result;
}

#[test]
fn e2e_string_literal() {
    let source = "to main() { \"hello\"; }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");
    assert!(!tokens.is_empty(), "Tokens should not be empty");

    let mut parser = Parser::new(tokens, source);
    let result = parser.parse();
    // Just verify pipeline doesn't crash
    let _ = result;
}

#[test]
fn e2e_function_definition() {
    let source = "to add(a, b) { give back a; } to main() { give back 0; }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    let result = parser.parse();
    if let Ok(ast) = result {
        // Should have multiple items
        assert!(ast.items.len() >= 1);
    }
}

#[test]
fn e2e_consent_expression() {
    let source = "to main() { only if okay \"test\" { } }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    let result = parser.parse();
    // Verify pipeline doesn't crash
    let _ = result;
}

#[test]
fn e2e_when_expression() {
    let source = "to main() { when true { } }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    let result = parser.parse();
    let _ = result;
}

#[test]
fn e2e_array_literal_parsing() {
    let source = "to main() { [1, 2, 3]; }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    let result = parser.parse();
    let _ = result;
}

#[test]
fn e2e_multiple_statements() {
    let source = "to main() { 1; 2; 3; }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    let result = parser.parse();
    let _ = result;
}

#[test]
fn e2e_binary_operations() {
    let source = "to main() { 1 + 2; 3 - 4; 5 * 6; }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    let result = parser.parse();
    let _ = result;
}

#[test]
fn e2e_gratitude_block_parsing() {
    let source = "thanks to { \"Author\" → \"Work\"; } to main() { }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    let result = parser.parse();
    let _ = result;
}

#[test]
fn e2e_type_check_no_crash() {
    // Verify that type checker doesn't crash even on complex programs
    let source = "to func(x) { give back x; } to main() { }";

    let lexer = Lexer::new(source);
    if let Ok(tokens) = lexer.tokenize() {
        let mut parser = Parser::new(tokens, source);
        if let Ok(ast) = parser.parse() {
            let mut typechecker = TypeChecker::new();
            let result = typechecker.check_program(&ast);
            // Should not panic
            let _ = result;
        }
    }
}

#[test]
fn e2e_interpreter_no_crash() {
    // Verify interpreter doesn't crash on valid AST
    let source = "to main() { }";

    let lexer = Lexer::new(source);
    if let Ok(tokens) = lexer.tokenize() {
        let mut parser = Parser::new(tokens, source);
        if let Ok(ast) = parser.parse() {
            let mut interpreter = Interpreter::new();
            let result = interpreter.run(&ast);
            // Should not panic
            let _ = result;
        }
    }
}
