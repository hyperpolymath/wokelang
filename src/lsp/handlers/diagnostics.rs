// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! Diagnostics handler

use tower_lsp::lsp_types::*;

use crate::lsp::Backend;

/// Publish diagnostics for a document
pub async fn publish_diagnostics(backend: &Backend, uri: &Url) {
    let diagnostics = collect_diagnostics(backend, uri);

    backend
        .client
        .publish_diagnostics(uri.clone(), diagnostics, None)
        .await;
}

/// Collect all diagnostics for a document
fn collect_diagnostics(backend: &Backend, uri: &Url) -> Vec<Diagnostic> {
    let mut diagnostics = Vec::new();

    // Get document
    let doc = match backend.document_map.get(uri) {
        Some(d) => d,
        None => return diagnostics,
    };

    // Try to tokenize
    if let Err(err) = doc.tokens() {
        diagnostics.push(Diagnostic {
            range: Range {
                start: Position::new(0, 0),
                end: Position::new(0, 1),
            },
            severity: Some(DiagnosticSeverity::ERROR),
            code: None,
            source: Some("wokelang-lexer".to_string()),
            message: err.clone(),
            ..Default::default()
        });
        return diagnostics; // Can't proceed without tokens
    }

    // Try to parse
    if let Err(err) = doc.ast() {
        diagnostics.push(Diagnostic {
            range: Range {
                start: Position::new(0, 0),
                end: Position::new(0, 1),
            },
            severity: Some(DiagnosticSeverity::ERROR),
            code: None,
            source: Some("wokelang-parser".to_string()),
            message: err.clone(),
            ..Default::default()
        });
        return diagnostics; // Can't lint without AST
    }

    // Typecheck (if it fails, type_env will be None, but we don't report it as error
    // since parse errors are already reported)
    let _ = doc.type_env();

    // TODO: Add linter diagnostics

    diagnostics
}
