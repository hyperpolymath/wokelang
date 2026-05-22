// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! Completion handler

use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;

use crate::lsp::stdlib_metadata::get_stdlib_completions;
use crate::lsp::Backend;

/// WokeLang keywords for completion
const KEYWORDS: &[&str] = &[
    "to",
    "give",
    "back",
    "remember",
    "when",
    "is",
    "otherwise",
    "repeat",
    "times",
    "only",
    "if",
    "okay",
    "attempt",
    "safely",
    "handle",
    "reassure",
    "complain",
    "type",
    "use",
    "renamed",
    "as",
    "hello",
    "goodbye",
    "worker",
    "side",
    "quest",
    "spawn",
    "superpower",
    "thanks",
    "for",
    "each",
    "in",
    "measured",
    "then",
    "and",
    "or",
    "not",
    "true",
    "false",
];

/// Standard library modules
const STDLIB_MODULES: &[&str] = &[
    "math", "string", "array", "io", "json", "time", "net", "chan",
];

/// Handle completion request
pub async fn completion(
    backend: &Backend,
    params: CompletionParams,
) -> Result<Option<CompletionResponse>> {
    let uri = params.text_document_position.text_document.uri;
    let position = params.text_document_position.position;

    // Get document
    let doc = match backend.document_map.get(&uri) {
        Some(d) => d,
        None => return Ok(None),
    };

    // Get word at cursor
    let word = doc
        .word_at_position(position.line, position.character)
        .unwrap_or_default();

    let mut items = Vec::new();

    // Check if we're after "std.module." for function completion
    if word.starts_with("std.") && word.matches('.').count() >= 2 {
        // Extract module name (e.g., "std.math." -> "math")
        let parts: Vec<&str> = word.split('.').collect();
        if parts.len() >= 2 {
            let module = parts[1];
            items.extend(get_stdlib_completions(module));
        }
    }
    // Check if we're after "std." for module completion
    else if word.starts_with("std.") || word == "std" {
        // Complete stdlib modules
        for module in STDLIB_MODULES {
            items.push(CompletionItem {
                label: module.to_string(),
                kind: Some(CompletionItemKind::MODULE),
                detail: Some(format!("Standard library module: {}", module)),
                documentation: Some(Documentation::String(format!(
                    "WokeLang standard library module for {} operations",
                    module
                ))),
                sort_text: Some(format!("0_{}", module)),
                ..Default::default()
            });
        }
    } else {
        // Add keywords
        for keyword in KEYWORDS {
            items.push(CompletionItem {
                label: keyword.to_string(),
                kind: Some(CompletionItemKind::KEYWORD),
                detail: Some("Keyword".to_string()),
                sort_text: Some(format!("1_{}", keyword)),
                ..Default::default()
            });
        }

        // Add local symbols from type environment
        if let Some(type_env) = doc.type_env() {
            for (name, ty) in &type_env.bindings {
                let kind = match ty {
                    crate::typechecker::TypeInfo::Function(_, _) => CompletionItemKind::FUNCTION,
                    _ => CompletionItemKind::VARIABLE,
                };

                items.push(CompletionItem {
                    label: name.clone(),
                    kind: Some(kind),
                    detail: Some(format!("{}", ty)),
                    documentation: Some(Documentation::String(format!("Type: {}", ty))),
                    sort_text: Some(format!("2_{}", name)),
                    ..Default::default()
                });
            }
        }
    }

    Ok(Some(CompletionResponse::Array(items)))
}
