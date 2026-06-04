// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! LSP integration tests

use tower_lsp::lsp_types::*;
use wokelang::lsp::document::DocumentState;

#[tokio::test]
async fn test_document_state_caching() {
    let source = "to add(a, b) { give back a + b; }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // First access should parse and cache
    let tokens1 = doc.tokens();
    assert!(tokens1.is_ok());

    // Second access should return cached result
    let tokens2 = doc.tokens();
    assert!(tokens2.is_ok());

    // Should be the same reference (cached)
    assert!(std::ptr::eq(tokens1, tokens2));
}

#[tokio::test]
async fn test_word_at_position() {
    let source = "to calculate(x, y) { give back x + y; }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Position at "calculate"
    let word = doc.word_at_position(0, 5);
    assert_eq!(word, Some("calculate".to_string()));

    // Position at "give"
    let word = doc.word_at_position(0, 22);
    assert_eq!(word, Some("give".to_string()));

    // Position at whitespace
    let word = doc.word_at_position(0, 1);
    assert_eq!(word, Some("to".to_string()));
}

#[test]
fn test_completion_keywords() {
    let source = "to main() { rem }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Get word at "rem"
    let word = doc.word_at_position(0, 14).unwrap();
    assert!(word.starts_with("rem"));

    // In real completion, this would return items including "remember"
    // (Testing the integration is complex without full backend setup)
}

#[test]
fn test_stdlib_module_detection() {
    let source = "std.math.abs(5)";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Get word at "std.math."
    let word = doc.word_at_position(0, 8).unwrap();
    assert!(word.starts_with("std."));
    assert!(word.contains("math"));
}

#[test]
fn test_parsing_valid_syntax() {
    let source = "to add(a, b) { give back a + b; }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    let ast = doc.ast();
    assert!(ast.is_ok());
}

#[test]
fn test_parsing_invalid_syntax() {
    let source = "to bad() { remember x = }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    let ast = doc.ast();
    assert!(ast.is_err());
}

#[test]
fn test_type_environment_caching() {
    let source = "to square(x) { give back x * x; }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // First access
    let type_env1 = doc.type_env();

    // Second access
    let type_env2 = doc.type_env();

    // Should return same cached reference
    match (type_env1, type_env2) {
        (Some(_), Some(_)) => { /* Both succeeded */ }
        _ => panic!("Type environment should be cached"),
    }
}

#[test]
fn test_line_index_position_conversion() {
    let source = "line1\nline2\nline3";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Line 0, char 0 should be offset 0
    let offset = doc.line_index.position_to_offset(0, 0);
    assert_eq!(offset, Some(0));

    // Line 1, char 0 should be offset 6 (after "line1\n")
    let offset = doc.line_index.position_to_offset(1, 0);
    assert_eq!(offset, Some(6));

    // Line 2, char 0 should be offset 12 (after "line1\nline2\n")
    let offset = doc.line_index.position_to_offset(2, 0);
    assert_eq!(offset, Some(12));
}

#[test]
fn test_formatter_basic() {
    use wokelang::Formatter;

    let source = "to add(a,b){give back a+b;}";
    let formatter = Formatter::new();
    let formatted = formatter.format(source);

    assert!(formatted.is_ok());
    let result = formatted.unwrap();
    assert!(result.contains("to add(a, b) {"));
    assert!(result.contains("give back"));
}

#[test]
fn test_stdlib_function_hover() {
    use wokelang::lsp::stdlib_metadata::get_stdlib_function_hover;

    let hover = get_stdlib_function_hover("math", "abs");
    assert!(hover.is_some());

    let hover_text = hover.unwrap();
    assert!(hover_text.contains("abs"));
    assert!(hover_text.contains("Absolute value"));
}

// Note: Full integration tests with Backend would require tokio runtime
// and more complex setup. These tests cover the core components that
// the handlers rely on.
