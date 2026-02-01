// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! Hover handler

use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;

use crate::lsp::Backend;

/// Handle hover request
pub async fn hover(_backend: &Backend, _params: HoverParams) -> Result<Option<Hover>> {
    // TODO: Implement hover
    Ok(None)
}
