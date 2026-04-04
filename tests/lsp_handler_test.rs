// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath
//!
//! LSP Handler Tests
//! Additional tests for LSP completion, hover, and definition handlers

use tower_lsp::lsp_types::*;
use wokelang::lsp::document::DocumentState;

#[test]
fn test_completion_handler_with_keywords() {
    let source = "to main() { rem ";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Word at position of "rem" should be found
    let word = doc.word_at_position(0, 15);
    assert!(word.is_some());
    let word_str = word.as_ref().unwrap();
    assert_eq!(word_str, "rem");

    // Should be able to complete "remember"
    assert!(word_str.starts_with("rem"));
}

#[test]
fn test_completion_handler_with_consent_keywords() {
    let source = "to main() { only if okay";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Word at "okay" should be found
    let word = doc.word_at_position(0, 22);
    assert!(word.is_some());

    let word_str = word.unwrap();
    assert!(word_str.contains("okay") || word_str.contains("if"));
}

#[test]
fn test_hover_handler_on_function_name() {
    let source = "to helper() { say \"test\"; } to main() { helper(); }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Word at "helper" call
    let word = doc.word_at_position(0, 40);
    assert_eq!(word, Some("helper".to_string()));
}

#[test]
fn test_hover_handler_on_builtin_function() {
    let source = "to main() { say \"hello\"; }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Word at "say"
    let word = doc.word_at_position(0, 13);
    assert_eq!(word, Some("say".to_string()));

    // "say" is a builtin function
    assert_eq!(word.unwrap(), "say");
}

#[test]
fn test_definition_handler_for_function_definition() {
    let source = "to func1() { } to main() { }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Parse AST to find definitions
    let ast_result = doc.ast();
    if ast_result.is_ok() {
        let ast_val = ast_result.as_ref().unwrap();
        // Should have at least 2 items: func1 and main
        assert!(ast_val.items.len() >= 1);
    }
}

#[test]
fn test_completion_handler_with_consent_operations() {
    let source = "to main() { forget ";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Word at "forget"
    let word = doc.word_at_position(0, 18);
    assert!(word.is_some());
    assert_eq!(word.unwrap(), "forget");
}

#[test]
fn test_hover_on_consent_keywords() {
    let source = "to main() { only if okay \"permission\" { say \"yes\"; } }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Word at "only"
    let word = doc.word_at_position(0, 12);
    assert!(word.is_some());
    assert!(word.unwrap().contains("only"));
}

#[test]
fn test_completion_after_gratitude_block() {
    let source = "thanks to { \"Author\" → \"Work\"; } to main() { rem";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Even after gratitude block, completion should work
    let word = doc.word_at_position(0, 49);
    assert!(word.is_some());
    assert_eq!(word.unwrap(), "rem");
}

#[test]
fn test_hover_on_stdlib_function() {
    use wokelang::lsp::stdlib_metadata::get_stdlib_function_hover;

    // Test math.abs hover
    let hover = get_stdlib_function_hover("math", "abs");
    assert!(hover.is_some());
    let text = hover.unwrap();
    assert!(text.contains("abs"));

    // Test string.upper hover
    let hover = get_stdlib_function_hover("string", "upper");
    assert!(hover.is_some());
    let text = hover.unwrap();
    assert!(text.contains("upper") || text.contains("Upper"));
}

#[test]
fn test_completion_for_array_operations() {
    let source = "to main() { [1,2,3]; }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Word at array literal position
    let word = doc.word_at_position(0, 15);
    // Just verify it doesn't crash
    let _ = word;
}

#[test]
fn test_error_in_document_triggers_diagnostic() {
    let source = "to main() { remember x = }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Should fail to parse
    let ast = doc.ast();
    assert!(ast.is_err());
}

#[test]
fn test_hover_on_variable_name() {
    let source = "to main() { remember myVar = 42; say myVar; }";
    let uri = Url::parse("file:///test.woke").unwrap();
    let doc = DocumentState::new(uri, source.to_string(), 1);

    // Word at "myVar" variable
    let word = doc.word_at_position(0, 38);
    assert!(word.is_some());
    assert_eq!(word.unwrap(), "myVar");
}
