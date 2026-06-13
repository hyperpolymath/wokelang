// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! Document state management and caching

use once_cell::sync::OnceCell;
use tower_lsp::lsp_types::Url;

use crate::ast::Program;
use crate::lexer::{Lexer, Spanned as LexerSpanned, Token};
use crate::parser::Parser;
use crate::typechecker::{TypeChecker, TypeEnv};

use super::utils::LineIndex;

/// Document state with lazy-evaluated caches
pub struct DocumentState {
    pub uri: Url,
    pub version: i32,
    pub source: String,
    pub line_index: LineIndex,

    // Lazy-evaluated caches
    tokens: OnceCell<Result<Vec<LexerSpanned<Token>>, String>>,
    ast: OnceCell<Result<Program, String>>,
    type_env: OnceCell<Option<TypeEnv>>,
}

impl DocumentState {
    /// Create a new document state
    pub fn new(uri: Url, source: String, version: i32) -> Self {
        let line_index = LineIndex::new(&source);

        Self {
            uri,
            version,
            source,
            line_index,
            tokens: OnceCell::new(),
            ast: OnceCell::new(),
            type_env: OnceCell::new(),
        }
    }

    /// Get tokens (lazy evaluation)
    pub fn tokens(&self) -> &Result<Vec<LexerSpanned<Token>>, String> {
        self.tokens.get_or_init(|| {
            let lexer = Lexer::new(&self.source);
            lexer.tokenize().map_err(|e| format!("{}", e))
        })
    }

    /// Get AST (lazy evaluation)
    pub fn ast(&self) -> &Result<Program, String> {
        self.ast.get_or_init(|| {
            let tokens = match self.tokens() {
                Ok(t) => t,
                Err(e) => return Err(e.clone()),
            };

            let mut parser = Parser::new(tokens.clone(), &self.source);
            parser.parse().map_err(|e| format!("{}", e))
        })
    }

    /// Get type environment (lazy evaluation, returns reference)
    pub fn type_env(&self) -> Option<&TypeEnv> {
        self.type_env
            .get_or_init(|| {
                let ast = match self.ast() {
                    Ok(a) => a,
                    Err(_) => return None,
                };

                let mut typechecker = TypeChecker::new();
                match typechecker.check_program(ast) {
                    Ok(_) => Some(typechecker.take_env()),
                    Err(_) => None,
                }
            })
            .as_ref()
    }

    /// Get word at position (for completion/hover)
    pub fn word_at_position(&self, line: u32, character: u32) -> Option<String> {
        let offset = self.line_index.position_to_offset(line, character)?;

        // Find word boundaries
        let start = self.source[..offset]
            .rfind(|c: char| !c.is_alphanumeric() && c != '_' && c != '.')
            .map(|i| i + 1)
            .unwrap_or(0);

        let end = self.source[offset..]
            .find(|c: char| !c.is_alphanumeric() && c != '_' && c != '.')
            .map(|i| offset + i)
            .unwrap_or(self.source.len());

        if start < end {
            Some(self.source[start..end].to_string())
        } else {
            None
        }
    }
}
