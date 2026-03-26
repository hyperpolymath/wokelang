// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! Formatting handler

use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;

use crate::formatter::Formatter;
use crate::lsp::Backend;

/// Handle document formatting request
pub async fn formatting(
    backend: &Backend,
    params: DocumentFormattingParams,
) -> Result<Option<Vec<TextEdit>>> {
    let uri = params.text_document.uri;

    // Get document
    let doc = match backend.document_map.get(&uri) {
        Some(d) => d,
        None => return Ok(None),
    };

    // Format the source
    let formatter = Formatter::new();
    let formatted = match formatter.format(&doc.source) {
        Ok(f) => f,
        Err(_) => return Ok(None), // Formatting failed, return no edits
    };

    // Create a text edit that replaces the entire document
    let start = Position::new(0, 0);
    let end_line = doc.source.lines().count() as u32;
    let end_char = doc.source.lines().last().map(|l| l.len()).unwrap_or(0) as u32;
    let end = Position::new(end_line, end_char);

    let edit = TextEdit {
        range: Range { start, end },
        new_text: formatted,
    };

    Ok(Some(vec![edit]))
}
