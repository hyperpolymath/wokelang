// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! Definition handler

use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;

use crate::ast::{Statement, TopLevelItem};
use crate::lsp::utils::span_to_range;
use crate::lsp::Backend;

/// Handle go-to-definition request
pub async fn goto_definition(
    backend: &Backend,
    params: GotoDefinitionParams,
) -> Result<Option<GotoDefinitionResponse>> {
    let uri = params.text_document_position_params.text_document.uri;
    let position = params.text_document_position_params.position;

    // Get document
    let doc = match backend.document_map.get(&uri) {
        Some(d) => d,
        None => return Ok(None),
    };

    // Get word at cursor
    let word = match doc.word_at_position(position.line, position.character) {
        Some(w) => w,
        None => return Ok(None),
    };

    // Get AST
    let ast = match doc.ast() {
        Ok(a) => a,
        Err(_) => return Ok(None),
    };

    // Search for definition
    for item in &ast.items {
        match item {
            TopLevelItem::Function(func) => {
                // Check if this is the function we're looking for
                if func.name == word {
                    let range = span_to_range(&func.span, &doc.source);
                    return Ok(Some(GotoDefinitionResponse::Scalar(Location {
                        uri: uri.clone(),
                        range,
                    })));
                }

                // Check function body for variable declarations
                if let Some(location) = search_statements(&func.body, &word, &doc.source, &uri) {
                    return Ok(Some(GotoDefinitionResponse::Scalar(location)));
                }
            }
            TopLevelItem::ConstDef(const_def) => {
                if const_def.name == word {
                    let range = span_to_range(&const_def.span, &doc.source);
                    return Ok(Some(GotoDefinitionResponse::Scalar(Location {
                        uri: uri.clone(),
                        range,
                    })));
                }
            }
            TopLevelItem::TypeDef(type_def) => {
                if type_def.name == word {
                    let range = span_to_range(&type_def.span, &doc.source);
                    return Ok(Some(GotoDefinitionResponse::Scalar(Location {
                        uri: uri.clone(),
                        range,
                    })));
                }
            }
            _ => {}
        }
    }

    Ok(None)
}

/// Search statements for variable declarations
fn search_statements(
    statements: &[Statement],
    target: &str,
    source: &str,
    uri: &Url,
) -> Option<Location> {
    for stmt in statements {
        match stmt {
            Statement::VarDecl(var_decl) if var_decl.name == *target => {
                let range = span_to_range(&var_decl.span, source);
                return Some(Location {
                    uri: uri.clone(),
                    range,
                });
            }
            Statement::Conditional(cond) => {
                if let Some(loc) = search_statements(&cond.then_branch, target, source, uri) {
                    return Some(loc);
                }
                if let Some(ref else_stmts) = cond.else_branch {
                    if let Some(loc) = search_statements(else_stmts, target, source, uri) {
                        return Some(loc);
                    }
                }
            }
            Statement::Loop(loop_stmt) => {
                if let Some(loc) = search_statements(&loop_stmt.body, target, source, uri) {
                    return Some(loc);
                }
            }
            Statement::AttemptBlock(attempt) => {
                if let Some(loc) = search_statements(&attempt.body, target, source, uri) {
                    return Some(loc);
                }
            }
            Statement::ConsentBlock(consent) => {
                if let Some(loc) = search_statements(&consent.body, target, source, uri) {
                    return Some(loc);
                }
            }
            _ => {}
        }
    }
    None
}
