// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! Definition handler

use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;

use crate::lsp::Backend;

/// Handle go-to-definition request
pub async fn goto_definition(
    _backend: &Backend,
    _params: GotoDefinitionParams,
) -> Result<Option<GotoDefinitionResponse>> {
    // TODO: Implement go-to-definition
    Ok(None)
}
