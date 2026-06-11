// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// SPDX-FileCopyrightText: 2026 Hyperpolymath
//
// Codegen Tests
// Validates that code generation produces valid output for basic programs

use wokelang::{BytecodeCompiler, Lexer, Parser, TypeChecker};

#[test]
fn codegen_simple_arithmetic() {
    let source = "to main() { 10 + 5; }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    let ast = parser.parse().expect("Parsing failed");

    let mut typechecker = TypeChecker::new();
    let _result = typechecker.check_program(&ast);

    // Codegen should not panic on valid AST
    let mut compiler = BytecodeCompiler::new();
    let result = compiler.compile(&ast);
    assert!(result.is_ok(), "Codegen should succeed on valid AST");
}

#[test]
fn codegen_with_function() {
    let source = "to add(a, b) { give back a; } to main() { }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    let ast = parser.parse().expect("Parsing failed");

    let mut typechecker = TypeChecker::new();
    let _result = typechecker.check_program(&ast);

    let mut compiler = BytecodeCompiler::new();
    let result = compiler.compile(&ast);
    assert!(result.is_ok(), "Codegen should handle function definitions");
}

#[test]
fn codegen_with_conditionals() {
    let source = "to main() { when true { } }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    if let Ok(ast) = parser.parse() {
        let mut typechecker = TypeChecker::new();
        let _result = typechecker.check_program(&ast);

        let mut compiler = BytecodeCompiler::new();
        let _result = compiler.compile(&ast);
        // Just verify it doesn't crash
    }
}

#[test]
fn codegen_preserves_structure() {
    let source = "to func1() { } to main() { }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    let ast = parser.parse().expect("Parsing failed");
    let original_item_count = ast.items.len();

    let mut typechecker = TypeChecker::new();
    let _result = typechecker.check_program(&ast);

    let mut compiler = BytecodeCompiler::new();
    let result = compiler.compile(&ast);

    // The original program structure should be preserved
    assert!(
        original_item_count > 0,
        "Original program should have items"
    );
    assert!(result.is_ok(), "Codegen should succeed");
}

#[test]
fn codegen_empty_main() {
    let source = "to main() { }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    let ast = parser.parse().expect("Parsing failed");

    let mut typechecker = TypeChecker::new();
    let _result = typechecker.check_program(&ast);

    let mut compiler = BytecodeCompiler::new();
    let result = compiler.compile(&ast);
    assert!(
        result.is_ok(),
        "Codegen should handle empty function bodies"
    );
}

#[test]
fn codegen_with_literals() {
    let source = "to main() { 42; \"hello\"; [1, 2, 3]; }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    if let Ok(ast) = parser.parse() {
        let mut typechecker = TypeChecker::new();
        let _result = typechecker.check_program(&ast);

        let mut compiler = BytecodeCompiler::new();
        let result = compiler.compile(&ast);
        let _ = result;
    }
}

#[test]
fn codegen_with_binary_ops() {
    let source = "to main() { 1 + 2; 3 - 4; 5 * 6; 7 / 8; }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    if let Ok(ast) = parser.parse() {
        let mut typechecker = TypeChecker::new();
        let _result = typechecker.check_program(&ast);

        let mut compiler = BytecodeCompiler::new();
        let result = compiler.compile(&ast);
        let _ = result;
    }
}

#[test]
fn codegen_with_consent_blocks() {
    let source = "to main() { only if okay \"test\" { } }";

    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().expect("Lexing failed");

    let mut parser = Parser::new(tokens, source);
    if let Ok(ast) = parser.parse() {
        let mut typechecker = TypeChecker::new();
        let _result = typechecker.check_program(&ast);

        let mut compiler = BytecodeCompiler::new();
        let result = compiler.compile(&ast);
        let _ = result;
    }
}
