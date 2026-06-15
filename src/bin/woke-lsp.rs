// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
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

    let (service, socket) = LspService::new(Backend::new);

    eprintln!("WokeLang LSP Server initialized");

    // Run the server
    Server::new(stdin, stdout, socket).serve(service).await;

    eprintln!("WokeLang LSP Server shutdown");
}
