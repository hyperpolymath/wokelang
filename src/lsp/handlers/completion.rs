// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! Completion handler

use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;

use crate::lsp::Backend;

/// Handle completion request
pub async fn completion(
    _backend: &Backend,
    _params: CompletionParams,
) -> Result<Option<CompletionResponse>> {
    // TODO: Implement completion
    Ok(None)
}
