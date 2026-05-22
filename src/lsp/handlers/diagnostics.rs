// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! Diagnostics handler

use tower_lsp::lsp_types::*;

use crate::linter::{Linter, Severity};
use crate::lsp::utils::span_to_range;
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
            code: Some(NumberOrString::String("lex-error".to_string())),
            source: Some("wokelang-lexer".to_string()),
            message: err.clone(),
            ..Default::default()
        });
        return diagnostics; // Can't proceed without tokens
    }

    // Try to parse
    let ast = match doc.ast() {
        Ok(a) => a,
        Err(err) => {
            diagnostics.push(Diagnostic {
                range: Range {
                    start: Position::new(0, 0),
                    end: Position::new(0, 1),
                },
                severity: Some(DiagnosticSeverity::ERROR),
                code: Some(NumberOrString::String("parse-error".to_string())),
                source: Some("wokelang-parser".to_string()),
                message: err.clone(),
                ..Default::default()
            });
            return diagnostics; // Can't lint without AST
        }
    };

    // Typecheck (errors are silent, we just want to populate the type env)
    let _ = doc.type_env();

    // Run linter
    let mut linter = Linter::new();
    let lint_diagnostics = linter.lint(ast);

    // Convert linter diagnostics to LSP diagnostics
    for lint_diag in lint_diagnostics {
        let severity = match lint_diag.severity {
            Severity::Error => DiagnosticSeverity::ERROR,
            Severity::Warning => DiagnosticSeverity::WARNING,
            Severity::Info => DiagnosticSeverity::INFORMATION,
        };

        diagnostics.push(Diagnostic {
            range: span_to_range(&lint_diag.span, &doc.source),
            severity: Some(severity),
            code: Some(NumberOrString::String(lint_diag.code)),
            source: Some("wokelang-linter".to_string()),
            message: lint_diag.message,
            ..Default::default()
        });
    }

    diagnostics
}
