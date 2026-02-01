// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! WokeLang Language Server Protocol (LSP) Server
//!
//! This binary provides IDE integration for WokeLang through the Language Server Protocol.

use tower_lsp::{LspService, Server};
use wokelang::lsp::Backend;

#[tokio::main]
async fn main() {
    // Initialize logging (stderr for LSP)
    eprintln!("WokeLang LSP Server starting...");

    // Create LSP service
    let stdin = tokio::io::stdin();
    let stdout = tokio::io::stdout();

    let (service, socket) = LspService::new(|client| Backend::new(client));

    eprintln!("WokeLang LSP Server initialized");

    // Run the server
    Server::new(stdin, stdout, socket).serve(service).await;

    eprintln!("WokeLang LSP Server shutdown");
}
