// SPDX-License-Identifier: MPL-2.0
//! WokeLang Parser
//!
//! Converts a stream of tokens into an Abstract Syntax Tree (AST).
//! Uses recursive descent parsing with Pratt parsing for expression precedence.

use crate::ast::*;
use crate::lexer::{Spanned as LexerSpanned, Token};
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
    tokens: Vec<LexerSpanned<Token>>,
    source: &'a str,
    current: usize,
    /// When true, a `{` following an identifier is not treated as the start of
    /// a record literal. Used in positions like a `decide based on` scrutinee
    /// where the `{` opens the match block, not a record (cf. how Rust
    /// disambiguates `if x { }` from a struct literal).
    no_struct_literal: bool,
}

/// Operator precedence levels (higher = tighter binding)
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
enum Precedence {
    None = 0,
    Or = 1,         // or
    And = 2,        // and
    Equality = 3,   // == !=
    Comparison = 4, // < > <= >=
    Term = 5,       // + -
    Factor = 6,     // * / %
    Unary = 7,      // - not
    Call = 8,       // f(x) arr[i]
    Primary = 9,
}

impl<'a> Parser<'a> {
    /// Create a new parser
    pub fn new(tokens: Vec<LexerSpanned<Token>>, source: &'a str) -> Self {
        Self {
            tokens,
            source,
            current: 0,
            no_struct_literal: false,
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

    // ====== Helper Methods ======

    /// Check if we're at end of tokens
    fn is_at_end(&self) -> bool {
        matches!(self.peek(), Token::Eof)
    }

    /// Peek at current token
    fn peek(&self) -> &Token {
        if self.current < self.tokens.len() {
            &self.tokens[self.current].value
        } else {
            &Token::Eof
        }
    }

    /// Peek at next token (lookahead)
    fn peek_next(&self) -> &Token {
        if self.current + 1 < self.tokens.len() {
            &self.tokens[self.current + 1].value
        } else {
            &Token::Eof
        }
    }

    /// Get current token span
    fn current_span(&self) -> Span {
        if self.current < self.tokens.len() {
            self.tokens[self.current].span.clone()
        } else {
            let len = self.source.len();
            len..len
        }
    }

    /// Advance to next token and return previous
    fn advance(&mut self) -> &Token {
        if !self.is_at_end() {
            self.current += 1;
        }
        if self.current > 0 && self.current - 1 < self.tokens.len() {
            &self.tokens[self.current - 1].value
        } else {
            &Token::Eof
        }
    }

    /// Check if current token matches any of the given types
    fn match_tokens(&mut self, tokens: &[Token]) -> bool {
        for token in tokens {
            if std::mem::discriminant(self.peek()) == std::mem::discriminant(token) {
                self.advance();
                return true;
            }
        }
        false
    }

    /// Expect a specific token or return error
    fn expect(&mut self, expected: Token, message: &str) -> Result<Span, ParseError> {
        if std::mem::discriminant(self.peek()) == std::mem::discriminant(&expected) {
            let span = self.current_span();
            self.advance();
            Ok(span)
        } else {
            Err(ParseError::ExpectedToken {
                expected: message.to_string(),
                found: format!("{}", self.peek()),
                span: self.current_span().into(),
            })
        }
    }

    /// Get identifier from current token
    fn expect_identifier(&mut self) -> Result<(String, Span), ParseError> {
        let span = self.current_span();
        if let Token::Identifier(name) = self.peek() {
            let name = name.clone();
            self.advance();
            Ok((name, span))
        } else {
            Err(ParseError::ExpectedToken {
                expected: "identifier".to_string(),
                found: format!("{}", self.peek()),
                span: span.into(),
            })
        }
    }

    // ====== Top-Level Parsing ======

    /// Parse a top-level item
    fn parse_top_level_item(&mut self) -> Result<TopLevelItem, ParseError> {
        match self.peek() {
            Token::To => Ok(TopLevelItem::Function(self.parse_function()?)),
            Token::Only => Ok(TopLevelItem::ConsentBlock(self.parse_consent_block()?)),
            Token::Thanks => Ok(TopLevelItem::GratitudeDecl(self.parse_gratitude_decl()?)),
            Token::Worker => Ok(TopLevelItem::WorkerDef(self.parse_worker_def()?)),
            Token::Side => Ok(TopLevelItem::SideQuestDef(self.parse_side_quest()?)),
            Token::Superpower => Ok(TopLevelItem::SuperpowerDecl(self.parse_superpower()?)),
            Token::Use => Ok(TopLevelItem::ModuleImport(self.parse_module_import()?)),
            Token::Hash => Ok(TopLevelItem::Pragma(self.parse_pragma()?)),
            Token::Type => Ok(TopLevelItem::TypeDef(self.parse_type_def()?)),
            Token::Const => Ok(TopLevelItem::ConstDef(self.parse_const_def()?)),
            _ => Err(ParseError::UnexpectedToken(
                format!("Unexpected top-level item: {}", self.peek()),
                self.current_span().into(),
            )),
        }
    }

    // ====== Expression Parsing (Pratt Parser) ======

    /// Parse an expression with given precedence
    fn parse_expression(&mut self) -> Result<Spanned<Expr>, ParseError> {
        self.parse_precedence(Precedence::None)
    }

    fn parse_precedence(&mut self, precedence: Precedence) -> Result<Spanned<Expr>, ParseError> {
        let start = self.current_span().start;

        // Parse prefix expression
        let mut expr = self.parse_prefix()?;

        // Parse infix expressions while precedence allows
        while precedence < self.get_precedence() {
            expr = self.parse_infix(expr)?;
        }

        Ok(expr)
    }

    fn parse_prefix(&mut self) -> Result<Spanned<Expr>, ParseError> {
        let start = self.current_span().start;

        match self.peek().clone() {
            // Literals
            Token::Integer(n) => {
                self.advance();
                let end = self.tokens[self.current - 1].span.end;
                Ok(Spanned::new(Expr::Literal(Literal::Integer(n)), start..end))
            }
            Token::Float(f) => {
                self.advance();
                let end = self.tokens[self.current - 1].span.end;
                Ok(Spanned::new(Expr::Literal(Literal::Float(f)), start..end))
            }
            Token::String(s) => {
                self.advance();
                let end = self.tokens[self.current - 1].span.end;
                Ok(Spanned::new(Expr::Literal(Literal::String(s)), start..end))
            }
            Token::True => {
                self.advance();
                let end = self.tokens[self.current - 1].span.end;
                Ok(Spanned::new(Expr::Literal(Literal::Bool(true)), start..end))
            }
            Token::False => {
                self.advance();
                let end = self.tokens[self.current - 1].span.end;
                Ok(Spanned::new(
                    Expr::Literal(Literal::Bool(false)),
                    start..end,
                ))
            }

            // Identifier or function call or record literal
            Token::Identifier(name) => {
                self.advance();
                let end = self.tokens[self.current - 1].span.end;

                // Check if it's a record literal (Type { field: value, ... }).
                // Suppressed in `no_struct_literal` positions so the `{` can
                // instead open an enclosing block (e.g. a match block).
                if !self.no_struct_literal && matches!(self.peek(), Token::LBrace) {
                    self.parse_record_literal(name, start)
                }
                // Check if it's a function call
                else if matches!(self.peek(), Token::LParen) {
                    self.parse_call(name, start)
                } else {
                    Ok(Spanned::new(Expr::Identifier(name), start..end))
                }
            }

            // Unary operators
            Token::Minus => {
                self.advance();
                let operand = self.parse_precedence(Precedence::Unary)?;
                let end = operand.span.end;
                Ok(Spanned::new(
                    Expr::Unary(UnaryOp::Neg, Box::new(operand)),
                    start..end,
                ))
            }
            Token::Not => {
                self.advance();
                let operand = self.parse_precedence(Precedence::Unary)?;
                let end = operand.span.end;
                Ok(Spanned::new(
                    Expr::Unary(UnaryOp::Not, Box::new(operand)),
                    start..end,
                ))
            }

            // Parenthesized expression
            Token::LParen => {
                self.advance();
                let expr = self.parse_expression()?;
                self.expect(Token::RParen, ")")?;
                Ok(expr)
            }

            // Array literal
            Token::LBracket => self.parse_array_literal(),

            // Lambda expression
            Token::Pipe => self.parse_lambda(),

            // Result constructors
            Token::Okay => {
                self.advance();
                self.expect(Token::LParen, "(")?;
                let value = self.parse_expression()?;
                let end_span = self.expect(Token::RParen, ")")?;
                Ok(Spanned::new(
                    Expr::Okay(Box::new(value)),
                    start..end_span.end,
                ))
            }

            // Thanks literal
            Token::Thanks => {
                self.advance();
                self.expect(Token::LParen, "(")?;
                if let Token::String(name) = self.peek() {
                    let name = name.clone();
                    self.advance();
                    let end_span = self.expect(Token::RParen, ")")?;
                    Ok(Spanned::new(
                        Expr::GratitudeLiteral(name),
                        start..end_span.end,
                    ))
                } else {
                    Err(ParseError::ExpectedToken {
                        expected: "string".to_string(),
                        found: format!("{}", self.peek()),
                        span: self.current_span().into(),
                    })
                }
            }

            _ => Err(ParseError::InvalidExpr(self.current_span().into())),
        }
    }

    fn parse_infix(&mut self, left: Spanned<Expr>) -> Result<Spanned<Expr>, ParseError> {
        let start = left.span.start;

        match self.peek().clone() {
            // Binary operators
            Token::Plus
            | Token::Minus
            | Token::Star
            | Token::Slash
            | Token::Percent
            | Token::EqualEqual
            | Token::BangEqual
            | Token::Less
            | Token::Greater
            | Token::LessEqual
            | Token::GreaterEqual
            | Token::And
            | Token::Or => {
                let op = self.binary_op_from_token(self.peek())?;
                self.advance();
                let precedence = self.get_precedence_for_binop(&op);
                let right = self.parse_precedence(precedence)?;
                let end = right.span.end;
                Ok(Spanned::new(
                    Expr::Binary(op, Box::new(left), Box::new(right)),
                    start..end,
                ))
            }

            // Field access
            Token::Dot => {
                self.advance();
                let (field_name, _) = self.expect_identifier()?;
                let end = self.tokens[self.current - 1].span.end;
                Ok(Spanned::new(
                    Expr::FieldAccess(Box::new(left), field_name),
                    start..end,
                ))
            }

            // Array indexing
            Token::LBracket => {
                self.advance();
                let index = self.parse_expression()?;
                let end_span = self.expect(Token::RBracket, "]")?;
                Ok(Spanned::new(
                    Expr::Index(Box::new(left), Box::new(index)),
                    start..end_span.end,
                ))
            }

            // Call expression (for closures)
            Token::LParen if !matches!(left.node, Expr::Identifier(_)) => {
                self.advance();
                let mut args = Vec::new();
                if !matches!(self.peek(), Token::RParen) {
                    loop {
                        args.push(self.parse_expression()?);
                        if !self.match_tokens(&[Token::Comma]) {
                            break;
                        }
                    }
                }
                let end_span = self.expect(Token::RParen, ")")?;
                Ok(Spanned::new(
                    Expr::CallExpr(Box::new(left), args),
                    start..end_span.end,
                ))
            }

            _ => Ok(left),
        }
    }

    fn parse_record_literal(
        &mut self,
        type_name: String,
        start: usize,
    ) -> Result<Spanned<Expr>, ParseError> {
        self.expect(Token::LBrace, "{")?;

        let mut fields = Vec::new();
        if !matches!(self.peek(), Token::RBrace) {
            loop {
                let (field_name, _) = self.expect_identifier()?;
                self.expect(Token::Colon, ":")?;
                let field_value = self.parse_expression()?;
                fields.push((field_name, field_value));

                if !self.match_tokens(&[Token::Comma]) {
                    break;
                }
            }
        }

        let end_span = self.expect(Token::RBrace, "}")?;
        Ok(Spanned::new(
            Expr::RecordLiteral(type_name, fields),
            start..end_span.end,
        ))
    }

    fn parse_array_literal(&mut self) -> Result<Spanned<Expr>, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::LBracket, "[")?;

        let mut elements = Vec::new();
        if !matches!(self.peek(), Token::RBracket) {
            loop {
                elements.push(self.parse_expression()?);
                if !self.match_tokens(&[Token::Comma]) {
                    break;
                }
            }
        }

        let end_span = self.expect(Token::RBracket, "]")?;
        Ok(Spanned::new(Expr::Array(elements), start..end_span.end))
    }

    fn parse_lambda(&mut self) -> Result<Spanned<Expr>, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Pipe, "|")?;

        // Parse parameters
        let mut params = Vec::new();
        if !matches!(self.peek(), Token::Pipe) {
            loop {
                let (name, span) = self.expect_identifier()?;
                let ty = if self.match_tokens(&[Token::Colon]) {
                    Some(self.parse_type()?)
                } else {
                    None
                };
                params.push(Parameter { name, ty, span });

                if !self.match_tokens(&[Token::Comma]) {
                    break;
                }
            }
        }
        self.expect(Token::Pipe, "|")?;

        // Check what comes after parameters
        let (return_type, body) = if matches!(self.peek(), Token::LBrace) {
            // Block body without return type annotation
            self.advance();
            let mut stmts = Vec::new();
            while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
                stmts.push(self.parse_statement()?);
            }
            self.expect(Token::RBrace, "}")?;
            (None, LambdaBody::Block(stmts))
        } else {
            // Expression body, possibly with return type
            // Check for return type annotation: |x, y| -> Type expr
            // vs bare expression: |x, y| expr
            let return_type = if self.match_tokens(&[Token::Arrow, Token::AsciiArrow]) {
                // Could be return type or start of expression
                // If next token is a type keyword, parse as type
                if matches!(
                    self.peek(),
                    Token::TypeInt
                        | Token::TypeFloat
                        | Token::TypeString
                        | Token::TypeBool
                        | Token::LBracket
                        | Token::LParen
                ) {
                    Some(self.parse_type()?)
                } else if let Token::Identifier(_) = self.peek() {
                    // Could be type name - parse as type
                    Some(self.parse_type()?)
                } else {
                    // Arrow but no type - this is actually part of the expression
                    // Put the arrow back by decrementing current
                    self.current -= 1;
                    None
                }
            } else {
                None
            };

            let expr = self.parse_expression()?;
            (return_type, LambdaBody::Expr(Box::new(expr)))
        };

        let end = self.tokens[self.current - 1].span.end;
        Ok(Spanned::new(
            Expr::Lambda(LambdaExpr {
                params,
                return_type,
                body,
            }),
            start..end,
        ))
    }

    fn parse_call(&mut self, func_name: String, start: usize) -> Result<Spanned<Expr>, ParseError> {
        self.expect(Token::LParen, "(")?;

        let mut args = Vec::new();
        if !matches!(self.peek(), Token::RParen) {
            loop {
                args.push(self.parse_expression()?);
                if !self.match_tokens(&[Token::Comma]) {
                    break;
                }
            }
        }

        let end_span = self.expect(Token::RParen, ")")?;
        Ok(Spanned::new(
            Expr::Call(func_name, args),
            start..end_span.end,
        ))
    }

    fn get_precedence(&self) -> Precedence {
        match self.peek() {
            Token::Or => Precedence::Or,
            Token::And => Precedence::And,
            Token::EqualEqual | Token::BangEqual => Precedence::Equality,
            Token::Less | Token::Greater | Token::LessEqual | Token::GreaterEqual => {
                Precedence::Comparison
            }
            Token::Plus | Token::Minus => Precedence::Term,
            Token::Star | Token::Slash | Token::Percent => Precedence::Factor,
            Token::LParen | Token::LBracket | Token::Dot => Precedence::Call,
            _ => Precedence::None,
        }
    }

    fn get_precedence_for_binop(&self, op: &BinaryOp) -> Precedence {
        match op {
            BinaryOp::Or => Precedence::Or,
            BinaryOp::And => Precedence::And,
            BinaryOp::Eq | BinaryOp::NotEq => Precedence::Equality,
            BinaryOp::Lt | BinaryOp::Gt | BinaryOp::LtEq | BinaryOp::GtEq => Precedence::Comparison,
            BinaryOp::Add | BinaryOp::Sub => Precedence::Term,
            BinaryOp::Mul | BinaryOp::Div | BinaryOp::Mod => Precedence::Factor,
        }
    }

    fn binary_op_from_token(&self, token: &Token) -> Result<BinaryOp, ParseError> {
        match token {
            Token::Plus => Ok(BinaryOp::Add),
            Token::Minus => Ok(BinaryOp::Sub),
            Token::Star => Ok(BinaryOp::Mul),
            Token::Slash => Ok(BinaryOp::Div),
            Token::Percent => Ok(BinaryOp::Mod),
            Token::EqualEqual => Ok(BinaryOp::Eq),
            Token::BangEqual => Ok(BinaryOp::NotEq),
            Token::Less => Ok(BinaryOp::Lt),
            Token::Greater => Ok(BinaryOp::Gt),
            Token::LessEqual => Ok(BinaryOp::LtEq),
            Token::GreaterEqual => Ok(BinaryOp::GtEq),
            Token::And => Ok(BinaryOp::And),
            Token::Or => Ok(BinaryOp::Or),
            _ => Err(ParseError::UnexpectedToken(
                format!("Not a binary operator: {}", token),
                self.current_span().into(),
            )),
        }
    }

    // ====== Statement Parsing ======

    fn parse_statement(&mut self) -> Result<Statement, ParseError> {
        match self.peek() {
            Token::Remember => self.parse_var_decl(),
            Token::Give => self.parse_return(),
            Token::When => self.parse_conditional(),
            Token::Repeat => self.parse_loop(),
            Token::While => self.parse_while_loop(),
            Token::Break => self.parse_break(),
            Token::Continue => self.parse_continue(),
            Token::Attempt => self.parse_attempt_block(),
            Token::Only => Ok(Statement::ConsentBlock(self.parse_consent_block()?)),
            Token::Spawn => self.parse_worker_spawn(),
            Token::Send => self.parse_send_message(),
            Token::Receive => self.parse_receive_message(),
            Token::Await => self.parse_await_worker(),
            Token::Cancel => self.parse_cancel_worker(),
            Token::Complain => self.parse_complain(),
            Token::Decide => self.parse_decide(),
            Token::At => self.parse_emote_annotated(),
            Token::Identifier(_) => self.parse_assignment_or_expr(),
            _ => {
                // Expression statement
                let expr = self.parse_expression()?;
                self.expect(Token::Semicolon, ";")?;
                Ok(Statement::Expression(expr))
            }
        }
    }

    fn parse_var_decl(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Remember, "remember")?;
        let (name, _) = self.expect_identifier()?;
        self.expect(Token::Equal, "=")?;
        let value = self.parse_expression()?;

        // Check for unit measurement
        let unit = if self.match_tokens(&[Token::Measured]) {
            self.expect(Token::In, "in")?;
            let (unit_name, _) = self.expect_identifier()?;
            Some(unit_name)
        } else {
            None
        };

        let end_span = self.expect(Token::Semicolon, ";")?;
        Ok(Statement::VarDecl(VarDecl {
            name,
            value,
            unit,
            span: start..end_span.end,
        }))
    }

    fn parse_assignment_or_expr(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        let (name, _) = self.expect_identifier()?;

        if self.match_tokens(&[Token::Equal]) {
            // Assignment
            let value = self.parse_expression()?;
            let end_span = self.expect(Token::Semicolon, ";")?;
            Ok(Statement::Assignment(Assignment {
                target: name,
                value,
                span: start..end_span.end,
            }))
        } else {
            // It was actually an expression (function call)
            // Backtrack and parse as expression
            self.current -= 1;
            let expr = self.parse_expression()?;
            self.expect(Token::Semicolon, ";")?;
            Ok(Statement::Expression(expr))
        }
    }

    fn parse_return(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Give, "give")?;
        self.expect(Token::Back, "back")?;
        let value = self.parse_expression()?;
        let end_span = self.expect(Token::Semicolon, ";")?;
        Ok(Statement::Return(ReturnStmt {
            value,
            span: start..end_span.end,
        }))
    }

    fn parse_conditional(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::When, "when")?;
        let condition = self.parse_expression()?;
        self.expect(Token::LBrace, "{")?;

        let mut then_branch = Vec::new();
        while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
            then_branch.push(self.parse_statement()?);
        }
        self.expect(Token::RBrace, "}")?;

        let else_branch = if self.match_tokens(&[Token::Otherwise]) {
            self.expect(Token::LBrace, "{")?;
            let mut stmts = Vec::new();
            while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
                stmts.push(self.parse_statement()?);
            }
            let end_span = self.expect(Token::RBrace, "}")?;
            Some(stmts)
        } else {
            None
        };

        let end = self.tokens[self.current - 1].span.end;
        Ok(Statement::Conditional(Conditional {
            condition,
            then_branch,
            else_branch,
            span: start..end,
        }))
    }

    fn parse_loop(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Repeat, "repeat")?;
        let count = self.parse_expression()?;
        self.expect(Token::Times, "times")?;
        self.expect(Token::LBrace, "{")?;

        let mut body = Vec::new();
        while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
            body.push(self.parse_statement()?);
        }
        let end_span = self.expect(Token::RBrace, "}")?;

        Ok(Statement::Loop(Loop {
            count,
            body,
            span: start..end_span.end,
        }))
    }

    fn parse_while_loop(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::While, "while")?;
        let condition = self.parse_expression()?;
        self.expect(Token::LBrace, "{")?;

        let mut body = Vec::new();
        while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
            body.push(self.parse_statement()?);
        }
        let end_span = self.expect(Token::RBrace, "}")?;

        Ok(Statement::While(WhileLoop {
            condition,
            body,
            span: start..end_span.end,
        }))
    }

    fn parse_break(&mut self) -> Result<Statement, ParseError> {
        let span = self.expect(Token::Break, "break")?;
        self.expect(Token::Semicolon, ";")?;
        Ok(Statement::Break(span))
    }

    fn parse_continue(&mut self) -> Result<Statement, ParseError> {
        let span = self.expect(Token::Continue, "continue")?;
        self.expect(Token::Semicolon, ";")?;
        Ok(Statement::Continue(span))
    }

    fn parse_attempt_block(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Attempt, "attempt")?;
        self.expect(Token::Safely, "safely")?;
        self.expect(Token::LBrace, "{")?;

        let mut body = Vec::new();
        while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
            body.push(self.parse_statement()?);
        }
        self.expect(Token::RBrace, "}")?;

        self.expect(Token::Or, "or")?;
        self.expect(Token::Reassure, "reassure")?;

        let reassurance = if let Token::String(s) = self.peek() {
            let s = s.clone();
            self.advance();
            s
        } else {
            return Err(ParseError::ExpectedToken {
                expected: "string".to_string(),
                found: format!("{}", self.peek()),
                span: self.current_span().into(),
            });
        };

        let end_span = self.expect(Token::Semicolon, ";")?;
        Ok(Statement::AttemptBlock(AttemptBlock {
            body,
            reassurance,
            span: start..end_span.end,
        }))
    }

    fn parse_worker_spawn(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Spawn, "spawn")?;
        self.expect(Token::Worker, "worker")?;
        let (worker_name, _) = self.expect_identifier()?;
        let end_span = self.expect(Token::Semicolon, ";")?;
        Ok(Statement::WorkerSpawn(WorkerSpawn {
            worker_name,
            span: start..end_span.end,
        }))
    }

    fn parse_send_message(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Send, "send")?;
        let message = self.parse_expression()?;
        self.expect(Token::To, "to")?;
        let (target, _) = self.expect_identifier()?;
        let end_span = self.expect(Token::Semicolon, ";")?;
        Ok(Statement::SendMessage(SendMessage {
            message,
            target,
            span: start..end_span.end,
        }))
    }

    fn parse_receive_message(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Receive, "receive")?;
        self.expect(Token::From, "from")?;
        let (source, _) = self.expect_identifier()?;
        let end_span = self.expect(Token::Semicolon, ";")?;
        Ok(Statement::ReceiveMessage(ReceiveMessage {
            source,
            span: start..end_span.end,
        }))
    }

    fn parse_await_worker(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Await, "await")?;
        let (worker_name, _) = self.expect_identifier()?;
        let end_span = self.expect(Token::Semicolon, ";")?;
        Ok(Statement::AwaitWorker(AwaitWorker {
            worker_name,
            span: start..end_span.end,
        }))
    }

    fn parse_cancel_worker(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Cancel, "cancel")?;
        let (worker_name, _) = self.expect_identifier()?;
        let end_span = self.expect(Token::Semicolon, ";")?;
        Ok(Statement::CancelWorker(CancelWorker {
            worker_name,
            span: start..end_span.end,
        }))
    }

    fn parse_complain(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Complain, "complain")?;

        let message = if let Token::String(s) = self.peek() {
            let s = s.clone();
            self.advance();
            s
        } else {
            return Err(ParseError::ExpectedToken {
                expected: "string".to_string(),
                found: format!("{}", self.peek()),
                span: self.current_span().into(),
            });
        };

        let end_span = self.expect(Token::Semicolon, ";")?;
        Ok(Statement::Complain(ComplainStmt {
            message,
            span: start..end_span.end,
        }))
    }

    fn parse_decide(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Decide, "decide")?;
        self.expect(Token::Based, "based")?;
        self.expect(Token::On, "on")?;
        // Parse the scrutinee with record-literal syntax suppressed, so the `{`
        // that follows opens the match block rather than a record literal.
        let prev_no_struct_literal = self.no_struct_literal;
        self.no_struct_literal = true;
        let scrutinee = self.parse_expression()?;
        self.no_struct_literal = prev_no_struct_literal;
        self.expect(Token::LBrace, "{")?;

        let mut arms = Vec::new();
        while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
            arms.push(self.parse_match_arm()?);
        }
        let end_span = self.expect(Token::RBrace, "}")?;

        Ok(Statement::Decide(DecideStmt {
            scrutinee,
            arms,
            span: start..end_span.end,
        }))
    }

    fn parse_match_arm(&mut self) -> Result<MatchArm, ParseError> {
        let start = self.current_span().start;
        let pattern = self.parse_pattern()?;

        // Accept both arrow forms
        if !self.match_tokens(&[Token::Arrow, Token::AsciiArrow]) {
            return Err(ParseError::ExpectedToken {
                expected: "→ or ->".to_string(),
                found: format!("{}", self.peek()),
                span: self.current_span().into(),
            });
        }

        self.expect(Token::LBrace, "{")?;

        let mut body = Vec::new();
        while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
            body.push(self.parse_statement()?);
        }
        let end_span = self.expect(Token::RBrace, "}")?;

        Ok(MatchArm {
            pattern,
            body,
            span: start..end_span.end,
        })
    }

    fn parse_pattern(&mut self) -> Result<Pattern, ParseError> {
        match self.peek().clone() {
            Token::Integer(n) => {
                self.advance();
                Ok(Pattern::Literal(Literal::Integer(n)))
            }
            Token::String(s) => {
                self.advance();
                Ok(Pattern::Literal(Literal::String(s)))
            }
            Token::True => {
                self.advance();
                Ok(Pattern::Literal(Literal::Bool(true)))
            }
            Token::False => {
                self.advance();
                Ok(Pattern::Literal(Literal::Bool(false)))
            }
            Token::Underscore => {
                self.advance();
                Ok(Pattern::Wildcard)
            }
            Token::Okay => {
                self.advance();
                if self.match_tokens(&[Token::LParen]) {
                    let inner = self.parse_pattern()?;
                    self.expect(Token::RParen, ")")?;
                    Ok(Pattern::Constructor(
                        "Okay".to_string(),
                        Some(Box::new(inner)),
                    ))
                } else {
                    Ok(Pattern::Constructor("Okay".to_string(), None))
                }
            }
            Token::Identifier(name) => {
                let name = name.clone();
                self.advance();

                // Check if it's a constructor pattern (capitalized identifier followed by optional parens)
                if name.chars().next().map_or(false, |c| c.is_uppercase()) {
                    if self.match_tokens(&[Token::LParen]) {
                        let inner = self.parse_pattern()?;
                        self.expect(Token::RParen, ")")?;
                        Ok(Pattern::Constructor(name, Some(Box::new(inner))))
                    } else {
                        // Constructor without parameters
                        Ok(Pattern::Constructor(name, None))
                    }
                } else {
                    // Regular identifier pattern (binding)
                    Ok(Pattern::Identifier(name))
                }
            }
            _ => Err(ParseError::InvalidExpr(self.current_span().into())),
        }
    }

    fn parse_emote_annotated(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        let emote = self.parse_emote_tag()?;
        let statement = Box::new(self.parse_statement()?);
        let end = statement.span().end;

        Ok(Statement::EmoteAnnotated(EmoteAnnotatedStmt {
            emote,
            statement,
            span: start..end,
        }))
    }

    fn parse_emote_tag(&mut self) -> Result<EmoteTag, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::At, "@")?;
        let (name, _) = self.expect_identifier()?;

        let params = if self.match_tokens(&[Token::LParen]) {
            let mut params = Vec::new();
            if !matches!(self.peek(), Token::RParen) {
                loop {
                    let (param_name, _) = self.expect_identifier()?;
                    self.expect(Token::Equal, "=")?;

                    let value = match self.peek().clone() {
                        Token::Integer(n) => {
                            self.advance();
                            EmoteValue::Number(n as f64)
                        }
                        Token::Float(f) => {
                            self.advance();
                            EmoteValue::Number(f)
                        }
                        Token::String(s) => {
                            self.advance();
                            EmoteValue::String(s)
                        }
                        Token::Identifier(id) => {
                            self.advance();
                            EmoteValue::Identifier(id)
                        }
                        _ => return Err(ParseError::InvalidExpr(self.current_span().into())),
                    };

                    params.push(EmoteParam {
                        name: param_name,
                        value,
                    });

                    if !self.match_tokens(&[Token::Comma]) {
                        break;
                    }
                }
            }
            self.expect(Token::RParen, ")")?;
            params
        } else {
            Vec::new()
        };

        let end = self.tokens[self.current - 1].span.end;
        Ok(EmoteTag {
            name,
            params,
            span: start..end,
        })
    }

    // ====== Type Parsing ======

    fn parse_type(&mut self) -> Result<Type, ParseError> {
        match self.peek() {
            Token::TypeInt => {
                self.advance();
                Ok(Type::Basic("Int".to_string()))
            }
            Token::TypeFloat => {
                self.advance();
                Ok(Type::Basic("Float".to_string()))
            }
            Token::TypeString => {
                self.advance();
                Ok(Type::Basic("String".to_string()))
            }
            Token::TypeBool => {
                self.advance();
                Ok(Type::Basic("Bool".to_string()))
            }
            Token::LBracket => {
                self.advance();
                let elem_ty = self.parse_type()?;
                self.expect(Token::RBracket, "]")?;
                Ok(Type::Array(Box::new(elem_ty)))
            }
            Token::LParen => {
                // Function type: (T1, T2) -> R
                self.advance();
                let mut params = Vec::new();
                if !matches!(self.peek(), Token::RParen) {
                    loop {
                        params.push(self.parse_type()?);
                        if !self.match_tokens(&[Token::Comma]) {
                            break;
                        }
                    }
                }
                self.expect(Token::RParen, ")")?;
                self.expect(Token::Arrow, "-> or →")?;
                let ret = self.parse_type()?;
                Ok(Type::Function(params, Box::new(ret)))
            }
            Token::Identifier(name) => {
                let name = name.clone();
                self.advance();

                // Check for generic type: Result<T, E>
                if self.match_tokens(&[Token::Less]) {
                    let mut type_args = Vec::new();
                    loop {
                        type_args.push(self.parse_type()?);
                        if !self.match_tokens(&[Token::Comma]) {
                            break;
                        }
                    }
                    self.expect(Token::Greater, ">")?;
                    Ok(Type::Generic(name, type_args))
                } else {
                    Ok(Type::Basic(name))
                }
            }
            _ => Err(ParseError::ExpectedToken {
                expected: "type".to_string(),
                found: format!("{}", self.peek()),
                span: self.current_span().into(),
            }),
        }
    }

    // ====== Top-Level Item Parsing ======

    fn parse_function(&mut self) -> Result<FunctionDef, ParseError> {
        let start = self.current_span().start;

        // Optional emote annotation
        let emote = if matches!(self.peek(), Token::At) {
            Some(self.parse_emote_tag()?)
        } else {
            None
        };

        self.expect(Token::To, "to")?;
        let (name, _) = self.expect_identifier()?;

        // Type parameters: <T, U>
        let type_params = if self.match_tokens(&[Token::Less]) {
            let mut params = Vec::new();
            loop {
                let (param_name, _) = self.expect_identifier()?;
                // TODO: Parse trait bounds
                params.push(TypeParam {
                    name: param_name,
                    bounds: vec![],
                });
                if !self.match_tokens(&[Token::Comma]) {
                    break;
                }
            }
            self.expect(Token::Greater, ">")?;
            params
        } else {
            Vec::new()
        };

        // Parameters
        self.expect(Token::LParen, "(")?;
        let mut params = Vec::new();
        if !matches!(self.peek(), Token::RParen) {
            loop {
                let param_start = self.current_span().start;
                let (param_name, _) = self.expect_identifier()?;
                let ty = if self.match_tokens(&[Token::Colon]) {
                    Some(self.parse_type()?)
                } else {
                    None
                };
                let param_end = self.tokens[self.current - 1].span.end;
                params.push(Parameter {
                    name: param_name,
                    ty,
                    span: param_start..param_end,
                });
                if !self.match_tokens(&[Token::Comma]) {
                    break;
                }
            }
        }
        self.expect(Token::RParen, ")")?;

        // Return type
        let return_type = if self.match_tokens(&[Token::Arrow, Token::AsciiArrow]) {
            Some(self.parse_type()?)
        } else {
            None
        };

        self.expect(Token::LBrace, "{")?;

        // Optional hello message
        let hello = if self.match_tokens(&[Token::Hello]) {
            if let Token::String(msg) = self.peek() {
                let msg = msg.clone();
                self.advance();
                self.expect(Token::Semicolon, ";")?;
                Some(msg)
            } else {
                return Err(ParseError::ExpectedToken {
                    expected: "string".to_string(),
                    found: format!("{}", self.peek()),
                    span: self.current_span().into(),
                });
            }
        } else {
            None
        };

        // Function body
        let mut body = Vec::new();
        while !matches!(self.peek(), Token::Goodbye | Token::RBrace) && !self.is_at_end() {
            body.push(self.parse_statement()?);
        }

        // Optional goodbye message
        let goodbye = if self.match_tokens(&[Token::Goodbye]) {
            if let Token::String(msg) = self.peek() {
                let msg = msg.clone();
                self.advance();
                self.expect(Token::Semicolon, ";")?;
                Some(msg)
            } else {
                return Err(ParseError::ExpectedToken {
                    expected: "string".to_string(),
                    found: format!("{}", self.peek()),
                    span: self.current_span().into(),
                });
            }
        } else {
            None
        };

        let end_span = self.expect(Token::RBrace, "}")?;

        Ok(FunctionDef {
            emote,
            name,
            type_params,
            params,
            return_type,
            hello,
            body,
            goodbye,
            span: start..end_span.end,
        })
    }

    fn parse_consent_block(&mut self) -> Result<ConsentBlock, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Only, "only")?;
        self.expect(Token::If, "if")?;
        self.expect(Token::Okay, "okay")?;

        let permission = if let Token::String(s) = self.peek() {
            let s = s.clone();
            self.advance();
            s
        } else {
            return Err(ParseError::ExpectedToken {
                expected: "string".to_string(),
                found: format!("{}", self.peek()),
                span: self.current_span().into(),
            });
        };

        self.expect(Token::LBrace, "{")?;
        let mut body = Vec::new();
        while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
            body.push(self.parse_statement()?);
        }
        let end_span = self.expect(Token::RBrace, "}")?;

        Ok(ConsentBlock {
            permission,
            body,
            span: start..end_span.end,
        })
    }

    fn parse_gratitude_decl(&mut self) -> Result<GratitudeDecl, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Thanks, "thanks")?;
        self.expect(Token::To, "to")?;
        self.expect(Token::LBrace, "{")?;

        let mut entries = Vec::new();
        while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
            let entry_start = self.current_span().start;

            let recipient = if let Token::String(s) = self.peek() {
                let s = s.clone();
                self.advance();
                s
            } else {
                return Err(ParseError::ExpectedToken {
                    expected: "string".to_string(),
                    found: format!("{}", self.peek()),
                    span: self.current_span().into(),
                });
            };

            self.expect(Token::Arrow, "→ or ->")?;

            let reason = if let Token::String(s) = self.peek() {
                let s = s.clone();
                self.advance();
                s
            } else {
                return Err(ParseError::ExpectedToken {
                    expected: "string".to_string(),
                    found: format!("{}", self.peek()),
                    span: self.current_span().into(),
                });
            };

            let entry_end = self.expect(Token::Semicolon, ";")?;

            entries.push(GratitudeEntry {
                recipient,
                reason,
                span: entry_start..entry_end.end,
            });
        }

        let end_span = self.expect(Token::RBrace, "}")?;

        Ok(GratitudeDecl {
            entries,
            span: start..end_span.end,
        })
    }

    fn parse_worker_def(&mut self) -> Result<WorkerDef, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Worker, "worker")?;
        let (name, _) = self.expect_identifier()?;
        self.expect(Token::LBrace, "{")?;

        let mut body = Vec::new();
        while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
            body.push(self.parse_statement()?);
        }
        let end_span = self.expect(Token::RBrace, "}")?;

        Ok(WorkerDef {
            name,
            body,
            span: start..end_span.end,
        })
    }

    fn parse_side_quest(&mut self) -> Result<SideQuestDef, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Side, "side")?;
        self.expect(Token::Quest, "quest")?;
        let (name, _) = self.expect_identifier()?;
        self.expect(Token::LBrace, "{")?;

        let mut body = Vec::new();
        while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
            body.push(self.parse_statement()?);
        }
        let end_span = self.expect(Token::RBrace, "}")?;

        Ok(SideQuestDef {
            name,
            body,
            span: start..end_span.end,
        })
    }

    fn parse_superpower(&mut self) -> Result<SuperpowerDecl, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Superpower, "superpower")?;
        let (name, _) = self.expect_identifier()?;
        self.expect(Token::LBrace, "{")?;

        let mut body = Vec::new();
        while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
            body.push(self.parse_statement()?);
        }
        let end_span = self.expect(Token::RBrace, "}")?;

        Ok(SuperpowerDecl {
            name,
            body,
            span: start..end_span.end,
        })
    }

    fn parse_module_import(&mut self) -> Result<ModuleImport, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Use, "use")?;

        // Parse qualified name: foo.bar.baz
        let mut parts = Vec::new();
        let (first, _) = self.expect_identifier()?;
        parts.push(first);

        while self.match_tokens(&[Token::Dot]) {
            let (part, _) = self.expect_identifier()?;
            parts.push(part);
        }

        let path_end = self.tokens[self.current - 1].span.end;
        let path = QualifiedName {
            parts,
            span: start..path_end,
        };

        // Optional rename
        let rename = if self.match_tokens(&[Token::Renamed]) {
            let (name, _) = self.expect_identifier()?;
            Some(name)
        } else {
            None
        };

        let end_span = self.expect(Token::Semicolon, ";")?;

        Ok(ModuleImport {
            path,
            rename,
            span: start..end_span.end,
        })
    }

    fn parse_pragma(&mut self) -> Result<Pragma, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Hash, "#")?;

        let directive = match self.peek() {
            Token::Care => {
                self.advance();
                PragmaDirective::Care
            }
            Token::Strict => {
                self.advance();
                PragmaDirective::Strict
            }
            Token::Verbose => {
                self.advance();
                PragmaDirective::Verbose
            }
            _ => {
                return Err(ParseError::ExpectedToken {
                    expected: "pragma directive (care, strict, verbose)".to_string(),
                    found: format!("{}", self.peek()),
                    span: self.current_span().into(),
                })
            }
        };

        let enabled = if self.match_tokens(&[Token::On]) {
            true
        } else if self.match_tokens(&[Token::Or]) {
            // "or" is used for "off" in "#care or"
            false
        } else {
            return Err(ParseError::ExpectedToken {
                expected: "on or off".to_string(),
                found: format!("{}", self.peek()),
                span: self.current_span().into(),
            });
        };

        let end_span = self.expect(Token::Semicolon, ";")?;

        Ok(Pragma {
            directive,
            enabled,
            span: start..end_span.end,
        })
    }

    fn parse_type_def(&mut self) -> Result<TypeDef, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Type, "type")?;
        let (name, _) = self.expect_identifier()?;
        self.expect(Token::Equal, "=")?;

        // Parse type variant
        let definition = if matches!(self.peek(), Token::LBrace) {
            // Struct: { field: Type, ... }
            self.advance();
            let mut fields = Vec::new();
            while !matches!(self.peek(), Token::RBrace) && !self.is_at_end() {
                let (field_name, _) = self.expect_identifier()?;
                self.expect(Token::Colon, ":")?;
                let field_ty = self.parse_type()?;
                fields.push(Field {
                    name: field_name,
                    ty: field_ty,
                });
                if !self.match_tokens(&[Token::Comma]) {
                    break;
                }
            }
            self.expect(Token::RBrace, "}")?;
            TypeVariant::Struct(fields)
        } else {
            // Could be enum or alias - for now, treat as alias
            let ty = self.parse_type()?;
            TypeVariant::Alias(ty)
        };

        let end_span = self.expect(Token::Semicolon, ";")?;

        Ok(TypeDef {
            name,
            definition,
            span: start..end_span.end,
        })
    }

    fn parse_const_def(&mut self) -> Result<ConstDef, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Const, "const")?;
        let (name, _) = self.expect_identifier()?;
        self.expect(Token::Colon, ":")?;
        let ty = self.parse_type()?;
        self.expect(Token::Equal, "=")?;
        let value = self.parse_expression()?;
        let end_span = self.expect(Token::Semicolon, ";")?;

        Ok(ConstDef {
            name,
            ty,
            value,
            span: start..end_span.end,
        })
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

    #[test]
    fn test_parse_function() {
        let source = r#"
to greet(name: String) -> String {
    give back "Hello";
}
"#;
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().unwrap();

        assert_eq!(program.items.len(), 1);
        match &program.items[0] {
            TopLevelItem::Function(func) => {
                assert_eq!(func.name, "greet");
                assert_eq!(func.params.len(), 1);
                assert_eq!(func.params[0].name, "name");
            }
            other => panic!("Expected function, got {other:?}"),
        }
    }

    #[test]
    fn test_parse_expressions() {
        let source = "to test() { remember x = 1 + 2 * 3; }";
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().unwrap();

        assert_eq!(program.items.len(), 1);
    }

    #[test]
    fn test_parse_array_literal() {
        let source = "to test() { remember arr = [1, 2, 3]; }";
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().unwrap();

        assert_eq!(program.items.len(), 1);
    }

    #[test]
    fn test_parse_lambda() {
        // Lambda without arrow (expression body)
        let source = "to test() { remember f = |x, y| x + y; }";
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().unwrap();

        assert_eq!(program.items.len(), 1);
    }

    #[test]
    fn test_parse_conditional() {
        let source = r#"
to test() {
    when true {
        complain "yes";
    } otherwise {
        complain "no";
    }
}
"#;
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().unwrap();

        assert_eq!(program.items.len(), 1);
    }

    #[test]
    fn test_parse_loop() {
        let source = "to test() { repeat 5 times { complain \"hi\"; } }";
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().unwrap();

        assert_eq!(program.items.len(), 1);
    }

    #[test]
    fn test_parse_pattern_matching() {
        let source = r#"
to test(result: Result<Int, String>) {
    decide based on result {
        Okay(value) -> {
            complain "success";
        }
        _ -> {
            complain "failure";
        }
    }
}
"#;
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().unwrap();

        assert_eq!(program.items.len(), 1);
    }
}
