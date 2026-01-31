// SPDX-License-Identifier: PMPL-1.0-or-later
//! WokeLang Parser
//!
//! Converts a stream of tokens into an Abstract Syntax Tree (AST).

use crate::ast::*;
use crate::lexer::{Spanned, Token};
use miette::{Diagnostic, SourceSpan};
use thiserror::Error;

/// Parser error types
#[derive(Error, Debug, Diagnostic)]
pub enum ParseError {
    #[error("Unexpected token: {0}")]
    UnexpectedToken(String, #[label("here")] SourceSpan),

    #[error("Expected {expected}, found {found}")]
    ExpectedToken {
        expected: String,
        found: String,
        #[label("here")]
        span: SourceSpan,
    },

    #[error("Unexpected end of file")]
    UnexpectedEof(#[label("expected more input")] SourceSpan),

    #[error("Invalid expression")]
    InvalidExpr(#[label("invalid expression")] SourceSpan),
}

/// Parser state
pub struct Parser<'a> {
    tokens: Vec<Spanned<Token>>,
    source: &'a str,
    current: usize,
}

impl<'a> Parser<'a> {
    /// Create a new parser
    pub fn new(tokens: Vec<Spanned<Token>>, source: &'a str) -> Self {
        Self {
            tokens,
            source,
            current: 0,
        }
    }

    /// Parse a complete program
    pub fn parse(&mut self) -> Result<Program, ParseError> {
        let mut items = Vec::new();

        while !self.is_at_end() {
            items.push(self.parse_top_level_item()?);
        }

        Ok(Program { items })
    }

    /// Parse a top-level item
    fn parse_top_level_item(&mut self) -> Result<TopLevelItem, ParseError> {
        // Stub: For now, just handle function definitions
        // TODO: Implement full parser for all TopLevelItem variants

        // Skip any comments or whitespace
        while self.current < self.tokens.len() && self.peek_token_type() == "comment" {
            self.advance();
        }

        if self.is_at_end() {
            return Err(ParseError::UnexpectedEof((0..0).into()));
        }

        // For now, create a minimal function
        let func = FunctionDef {
            emote: None,
            name: "main".to_string(),
            type_params: vec![],
            params: vec![],
            return_type: None,
            hello: None,
            body: vec![],
            goodbye: None,
            span: 0..1,
        };

        Ok(TopLevelItem::Function(func))
    }

    /// Check if we're at end of tokens
    fn is_at_end(&self) -> bool {
        self.current >= self.tokens.len()
    }

    /// Get the type of current token
    fn peek_token_type(&self) -> &str {
        if self.is_at_end() {
            "eof"
        } else {
            // TODO: Implement proper token type checking
            "unknown"
        }
    }

    /// Advance to next token
    fn advance(&mut self) {
        if !self.is_at_end() {
            self.current += 1;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::lexer::Lexer;

    #[test]
    fn test_parse_empty() {
        let source = "";
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().unwrap();
        assert_eq!(program.items.len(), 0);
    }
}
