use crate::ast::*;
use crate::lexer::{Spanned as LexSpanned, Token};
use miette::{Diagnostic, SourceSpan};
use thiserror::Error;

#[derive(Error, Debug, Diagnostic)]
pub enum ParseError {
    #[error("Unexpected token: expected {expected}, found {found}")]
    #[diagnostic(code(wokelang::parser::unexpected_token))]
    UnexpectedToken {
        expected: String,
        found: String,
        #[source_code]
        src: String,
        #[label("here")]
        span: SourceSpan,
    },

    #[error("Unexpected end of input")]
    #[diagnostic(code(wokelang::parser::unexpected_eof))]
    UnexpectedEof,

    #[error("{message}")]
    #[diagnostic(code(wokelang::parser::general))]
    General {
        message: String,
        #[source_code]
        src: String,
        #[label("here")]
        span: SourceSpan,
    },
}

pub struct Parser<'src> {
    tokens: Vec<LexSpanned<Token>>,
    pos: usize,
    source: &'src str,
}

impl<'src> Parser<'src> {
    pub fn new(tokens: Vec<LexSpanned<Token>>, source: &'src str) -> Self {
        Self {
            tokens,
            pos: 0,
            source,
        }
    }

    pub fn parse(&mut self) -> Result<Program, ParseError> {
        let mut items = Vec::new();
        while !self.is_at_end() {
            items.push(self.parse_top_level_item()?);
        }
        Ok(Program { items })
    }

    fn parse_top_level_item(&mut self) -> Result<TopLevelItem, ParseError> {
        match self.peek() {
            Some(Token::To) => Ok(TopLevelItem::Function(self.parse_function_def(None)?)),
            Some(Token::At) => {
                let emote = self.parse_emote_tag()?;
                self.expect(Token::To)?;
                Ok(TopLevelItem::Function(self.parse_function_def(Some(emote))?))
            }
            Some(Token::Only) => Ok(TopLevelItem::ConsentBlock(self.parse_consent_block()?)),
            Some(Token::Thanks) => Ok(TopLevelItem::GratitudeDecl(self.parse_gratitude_decl()?)),
            Some(Token::Worker) => Ok(TopLevelItem::WorkerDef(self.parse_worker_def()?)),
            Some(Token::Side) => Ok(TopLevelItem::SideQuestDef(self.parse_side_quest_def()?)),
            Some(Token::Superpower) => {
                Ok(TopLevelItem::SuperpowerDecl(self.parse_superpower_decl()?))
            }
            Some(Token::Use) => Ok(TopLevelItem::ModuleImport(self.parse_module_import()?)),
            Some(Token::Hash) => Ok(TopLevelItem::Pragma(self.parse_pragma()?)),
            Some(Token::Type) => Ok(TopLevelItem::TypeDef(self.parse_type_def()?)),
            Some(Token::Const) => Ok(TopLevelItem::ConstDef(self.parse_const_def()?)),
            _ => Err(self.error("Expected top-level item")),
        }
    }

    // === Function Parsing ===

    fn parse_function_def(&mut self, emote: Option<EmoteTag>) -> Result<FunctionDef, ParseError> {
        let start = self.current_span().start;

        // 'to' already consumed if emote was present, otherwise consume it
        if emote.is_none() {
            self.expect(Token::To)?;
        }

        let name = self.expect_identifier()?;
        self.expect(Token::LParen)?;
        let params = self.parse_parameter_list()?;
        self.expect(Token::RParen)?;

        let return_type = if self.check(&Token::Arrow) || self.check(&Token::AsciiArrow) {
            self.advance();
            Some(self.parse_type()?)
        } else {
            None
        };

        self.expect(Token::LBrace)?;

        let hello = if self.check(&Token::Hello) {
            self.advance();
            let msg = self.expect_string()?;
            self.expect(Token::Semicolon)?;
            Some(msg)
        } else {
            None
        };

        let mut body = Vec::new();
        while !self.check(&Token::Goodbye) && !self.check(&Token::RBrace) {
            body.push(self.parse_statement()?);
        }

        let goodbye = if self.check(&Token::Goodbye) {
            self.advance();
            let msg = self.expect_string()?;
            self.expect(Token::Semicolon)?;
            Some(msg)
        } else {
            None
        };

        let end = self.current_span().end;
        self.expect(Token::RBrace)?;

        Ok(FunctionDef {
            emote,
            name,
            params,
            return_type,
            hello,
            body,
            goodbye,
            span: start..end,
        })
    }

    fn parse_parameter_list(&mut self) -> Result<Vec<Parameter>, ParseError> {
        let mut params = Vec::new();
        if self.check(&Token::RParen) {
            return Ok(params);
        }

        params.push(self.parse_parameter()?);
        while self.check(&Token::Comma) {
            self.advance();
            params.push(self.parse_parameter()?);
        }

        Ok(params)
    }

    fn parse_parameter(&mut self) -> Result<Parameter, ParseError> {
        let start = self.current_span().start;
        let name = self.expect_identifier()?;
        let ty = if self.check(&Token::Colon) {
            self.advance();
            Some(self.parse_type()?)
        } else {
            None
        };
        let end = self.previous_span().end;
        Ok(Parameter {
            name,
            ty,
            span: start..end,
        })
    }

    // === Consent Block ===

    fn parse_consent_block(&mut self) -> Result<ConsentBlock, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Only)?;
        self.expect(Token::If)?;
        self.expect(Token::Okay)?;
        let permission = self.expect_string()?;
        self.expect(Token::LBrace)?;
        let body = self.parse_statement_list()?;
        let end = self.current_span().end;
        self.expect(Token::RBrace)?;

        Ok(ConsentBlock {
            permission,
            body,
            span: start..end,
        })
    }

    // === Gratitude ===

    fn parse_gratitude_decl(&mut self) -> Result<GratitudeDecl, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Thanks)?;
        self.expect(Token::To)?;
        self.expect(Token::LBrace)?;

        let mut entries = Vec::new();
        while !self.check(&Token::RBrace) {
            entries.push(self.parse_gratitude_entry()?);
        }

        let end = self.current_span().end;
        self.expect(Token::RBrace)?;

        Ok(GratitudeDecl {
            entries,
            span: start..end,
        })
    }

    fn parse_gratitude_entry(&mut self) -> Result<GratitudeEntry, ParseError> {
        let start = self.current_span().start;
        let recipient = self.expect_string()?;
        if !self.check(&Token::Arrow) && !self.check(&Token::AsciiArrow) {
            return Err(self.error("Expected → or ->"));
        }
        self.advance();
        let reason = self.expect_string()?;
        let end = self.current_span().end;
        self.expect(Token::Semicolon)?;

        Ok(GratitudeEntry {
            recipient,
            reason,
            span: start..end,
        })
    }

    // === Worker/Side Quest/Superpower ===

    fn parse_worker_def(&mut self) -> Result<WorkerDef, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Worker)?;
        let name = self.expect_identifier()?;
        self.expect(Token::LBrace)?;
        let body = self.parse_statement_list()?;
        let end = self.current_span().end;
        self.expect(Token::RBrace)?;

        Ok(WorkerDef {
            name,
            body,
            span: start..end,
        })
    }

    fn parse_side_quest_def(&mut self) -> Result<SideQuestDef, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Side)?;
        self.expect(Token::Quest)?;
        let name = self.expect_identifier()?;
        self.expect(Token::LBrace)?;
        let body = self.parse_statement_list()?;
        let end = self.current_span().end;
        self.expect(Token::RBrace)?;

        Ok(SideQuestDef {
            name,
            body,
            span: start..end,
        })
    }

    fn parse_superpower_decl(&mut self) -> Result<SuperpowerDecl, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Superpower)?;
        let name = self.expect_identifier()?;
        self.expect(Token::LBrace)?;
        let body = self.parse_statement_list()?;
        let end = self.current_span().end;
        self.expect(Token::RBrace)?;

        Ok(SuperpowerDecl {
            name,
            body,
            span: start..end,
        })
    }

    // === Module Import ===

    fn parse_module_import(&mut self) -> Result<ModuleImport, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Use)?;
        let path = self.parse_qualified_name()?;
        let rename = if self.check(&Token::Renamed) {
            self.advance();
            Some(self.expect_identifier()?)
        } else {
            None
        };
        let end = self.current_span().end;
        self.expect(Token::Semicolon)?;

        Ok(ModuleImport {
            path,
            rename,
            span: start..end,
        })
    }

    fn parse_qualified_name(&mut self) -> Result<QualifiedName, ParseError> {
        let start = self.current_span().start;
        let mut parts = vec![self.expect_identifier()?];
        while self.check(&Token::Dot) {
            self.advance();
            parts.push(self.expect_identifier()?);
        }
        let end = self.previous_span().end;
        Ok(QualifiedName {
            parts,
            span: start..end,
        })
    }

    // === Pragma ===

    fn parse_pragma(&mut self) -> Result<Pragma, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Hash)?;

        let directive = match self.peek() {
            Some(Token::Care) => {
                self.advance();
                PragmaDirective::Care
            }
            Some(Token::Strict) => {
                self.advance();
                PragmaDirective::Strict
            }
            Some(Token::Verbose) => {
                self.advance();
                PragmaDirective::Verbose
            }
            _ => return Err(self.error("Expected pragma directive (care, strict, verbose)")),
        };

        let enabled = if self.check(&Token::Identifier(String::new())) {
            match self.peek() {
                Some(Token::Identifier(s)) if s == "on" => {
                    self.advance();
                    true
                }
                Some(Token::Identifier(s)) if s == "off" => {
                    self.advance();
                    false
                }
                _ => return Err(self.error("Expected 'on' or 'off'")),
            }
        } else {
            return Err(self.error("Expected 'on' or 'off'"));
        };

        let end = self.current_span().end;
        self.expect(Token::Semicolon)?;

        Ok(Pragma {
            directive,
            enabled,
            span: start..end,
        })
    }

    // === Type Definition ===

    fn parse_type_def(&mut self) -> Result<TypeDef, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Type)?;
        let name = self.expect_identifier()?;
        self.expect(Token::Equal)?;

        let definition = if self.check(&Token::LBrace) {
            self.advance();
            let fields = self.parse_field_list()?;
            self.expect(Token::RBrace)?;
            TypeVariant::Struct(fields)
        } else {
            // Check if it's an enum (has |) or an alias
            let first_type = self.parse_type()?;
            if self.check(&Token::Pipe) {
                let mut variants = vec![Variant {
                    name: match &first_type {
                        Type::Basic(n) => n.clone(),
                        _ => return Err(self.error("Enum variant must be an identifier")),
                    },
                    fields: vec![],
                }];
                while self.check(&Token::Pipe) {
                    self.advance();
                    variants.push(self.parse_variant()?);
                }
                TypeVariant::Enum(variants)
            } else {
                TypeVariant::Alias(first_type)
            }
        };

        let end = self.current_span().end;
        self.expect(Token::Semicolon)?;

        Ok(TypeDef {
            name,
            definition,
            span: start..end,
        })
    }

    fn parse_field_list(&mut self) -> Result<Vec<Field>, ParseError> {
        let mut fields = Vec::new();
        if self.check(&Token::RBrace) {
            return Ok(fields);
        }

        fields.push(self.parse_field()?);
        while self.check(&Token::Comma) {
            self.advance();
            if self.check(&Token::RBrace) {
                break;
            }
            fields.push(self.parse_field()?);
        }

        Ok(fields)
    }

    fn parse_field(&mut self) -> Result<Field, ParseError> {
        let name = self.expect_identifier()?;
        self.expect(Token::Colon)?;
        let ty = self.parse_type()?;
        Ok(Field { name, ty })
    }

    fn parse_variant(&mut self) -> Result<Variant, ParseError> {
        let name = self.expect_identifier()?;
        let fields = if self.check(&Token::LParen) {
            self.advance();
            let mut types = vec![self.parse_type()?];
            while self.check(&Token::Comma) {
                self.advance();
                types.push(self.parse_type()?);
            }
            self.expect(Token::RParen)?;
            types
        } else {
            vec![]
        };
        Ok(Variant { name, fields })
    }

    // === Const Definition ===

    fn parse_const_def(&mut self) -> Result<ConstDef, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Const)?;
        let name = self.expect_identifier()?;
        self.expect(Token::Colon)?;
        let ty = self.parse_type()?;
        self.expect(Token::Equal)?;
        let value = self.parse_expression()?;
        let end = self.current_span().end;
        self.expect(Token::Semicolon)?;

        Ok(ConstDef {
            name,
            ty,
            value,
            span: start..end,
        })
    }

    // === Type Parsing ===

    fn parse_type(&mut self) -> Result<Type, ParseError> {
        if self.check(&Token::LBracket) {
            self.advance();
            let inner = self.parse_type()?;
            self.expect(Token::RBracket)?;
            return Ok(Type::Array(Box::new(inner)));
        }

        if self.check(&Token::Maybe) {
            self.advance();
            let inner = self.parse_type()?;
            return Ok(Type::Optional(Box::new(inner)));
        }

        if self.check(&Token::Ampersand) {
            self.advance();
            let inner = self.parse_type()?;
            return Ok(Type::Reference(Box::new(inner)));
        }

        match self.peek() {
            Some(Token::TypeString) => {
                self.advance();
                Ok(Type::Basic("String".to_string()))
            }
            Some(Token::TypeInt) => {
                self.advance();
                Ok(Type::Basic("Int".to_string()))
            }
            Some(Token::TypeFloat) => {
                self.advance();
                Ok(Type::Basic("Float".to_string()))
            }
            Some(Token::TypeBool) => {
                self.advance();
                Ok(Type::Basic("Bool".to_string()))
            }
            Some(Token::Identifier(name)) => {
                let name = name.clone();
                self.advance();
                Ok(Type::Basic(name))
            }
            _ => Err(self.error("Expected type")),
        }
    }

    // === Statement Parsing ===

    fn parse_statement_list(&mut self) -> Result<Vec<Statement>, ParseError> {
        let mut stmts = Vec::new();
        while !self.check(&Token::RBrace) && !self.is_at_end() {
            stmts.push(self.parse_statement()?);
        }
        Ok(stmts)
    }

    fn parse_statement(&mut self) -> Result<Statement, ParseError> {
        // Check for emote-annotated statement
        if self.check(&Token::At) {
            let emote = self.parse_emote_tag()?;
            let stmt = self.parse_statement()?;
            let span = emote.span.start..self.previous_span().end;
            return Ok(Statement::EmoteAnnotated(EmoteAnnotatedStmt {
                emote,
                statement: Box::new(stmt),
                span,
            }));
        }

        match self.peek() {
            Some(Token::Remember) => self.parse_var_decl(),
            Some(Token::Give) => self.parse_return_stmt(),
            Some(Token::When) => self.parse_conditional(),
            Some(Token::Repeat) => self.parse_loop(),
            Some(Token::Attempt) => self.parse_attempt_block(),
            Some(Token::Only) => Ok(Statement::ConsentBlock(self.parse_consent_block()?)),
            Some(Token::Spawn) => self.parse_worker_spawn(),
            Some(Token::Complain) => self.parse_complain_stmt(),
            Some(Token::Decide) => self.parse_decide_stmt(),
            Some(Token::Identifier(_)) => {
                // Could be assignment or expression
                let start = self.current_span().start;
                let expr = self.parse_expression()?;

                // Check if this is an assignment
                if self.check(&Token::Equal) {
                    if let Expr::Identifier(name) = &expr.node {
                        let name = name.clone();
                        self.advance(); // consume '='
                        let value = self.parse_expression()?;
                        let end = self.current_span().end;
                        self.expect(Token::Semicolon)?;
                        return Ok(Statement::Assignment(Assignment {
                            target: name,
                            value,
                            span: start..end,
                        }));
                    }
                }

                self.expect(Token::Semicolon)?;
                Ok(Statement::Expression(expr))
            }
            _ => {
                let expr = self.parse_expression()?;
                self.expect(Token::Semicolon)?;
                Ok(Statement::Expression(expr))
            }
        }
    }

    fn parse_var_decl(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Remember)?;
        let name = self.expect_identifier()?;
        self.expect(Token::Equal)?;
        let value = self.parse_expression()?;

        let unit = if self.check(&Token::Measured) {
            self.advance();
            self.expect(Token::In)?;
            Some(self.expect_identifier()?)
        } else {
            None
        };

        let end = self.current_span().end;
        self.expect(Token::Semicolon)?;

        Ok(Statement::VarDecl(VarDecl {
            name,
            value,
            unit,
            span: start..end,
        }))
    }

    fn parse_return_stmt(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Give)?;
        self.expect(Token::Back)?;
        let value = self.parse_expression()?;
        let end = self.current_span().end;
        self.expect(Token::Semicolon)?;

        Ok(Statement::Return(ReturnStmt {
            value,
            span: start..end,
        }))
    }

    fn parse_conditional(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::When)?;
        let condition = self.parse_expression()?;
        self.expect(Token::LBrace)?;
        let then_branch = self.parse_statement_list()?;
        self.expect(Token::RBrace)?;

        let else_branch = if self.check(&Token::Otherwise) {
            self.advance();
            self.expect(Token::LBrace)?;
            let stmts = self.parse_statement_list()?;
            self.expect(Token::RBrace)?;
            Some(stmts)
        } else {
            None
        };

        let end = self.previous_span().end;

        Ok(Statement::Conditional(Conditional {
            condition,
            then_branch,
            else_branch,
            span: start..end,
        }))
    }

    fn parse_loop(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Repeat)?;
        let count = self.parse_expression()?;
        self.expect(Token::Times)?;
        self.expect(Token::LBrace)?;
        let body = self.parse_statement_list()?;
        let end = self.current_span().end;
        self.expect(Token::RBrace)?;

        Ok(Statement::Loop(Loop {
            count,
            body,
            span: start..end,
        }))
    }

    fn parse_attempt_block(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Attempt)?;
        self.expect(Token::Safely)?;
        self.expect(Token::LBrace)?;
        let body = self.parse_statement_list()?;
        self.expect(Token::RBrace)?;
        self.expect(Token::Or)?;
        self.expect(Token::Reassure)?;
        let reassurance = self.expect_string()?;
        let end = self.current_span().end;
        self.expect(Token::Semicolon)?;

        Ok(Statement::AttemptBlock(AttemptBlock {
            body,
            reassurance,
            span: start..end,
        }))
    }

    fn parse_worker_spawn(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Spawn)?;
        self.expect(Token::Worker)?;
        let worker_name = self.expect_identifier()?;
        let end = self.current_span().end;
        self.expect(Token::Semicolon)?;

        Ok(Statement::WorkerSpawn(WorkerSpawn {
            worker_name,
            span: start..end,
        }))
    }

    fn parse_complain_stmt(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Complain)?;
        let message = self.expect_string()?;
        let end = self.current_span().end;
        self.expect(Token::Semicolon)?;

        Ok(Statement::Complain(ComplainStmt {
            message,
            span: start..end,
        }))
    }

    fn parse_decide_stmt(&mut self) -> Result<Statement, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::Decide)?;
        self.expect(Token::Based)?;
        self.expect(Token::On)?;
        let scrutinee = self.parse_expression()?;
        self.expect(Token::LBrace)?;

        let mut arms = Vec::new();
        while !self.check(&Token::RBrace) {
            arms.push(self.parse_match_arm()?);
        }

        let end = self.current_span().end;
        self.expect(Token::RBrace)?;

        Ok(Statement::Decide(DecideStmt {
            scrutinee,
            arms,
            span: start..end,
        }))
    }

    fn parse_match_arm(&mut self) -> Result<MatchArm, ParseError> {
        let start = self.current_span().start;
        let pattern = self.parse_pattern()?;

        if !self.check(&Token::Arrow) && !self.check(&Token::AsciiArrow) {
            return Err(self.error("Expected → or ->"));
        }
        self.advance();

        self.expect(Token::LBrace)?;
        let body = self.parse_statement_list()?;
        let end = self.current_span().end;
        self.expect(Token::RBrace)?;

        Ok(MatchArm {
            pattern,
            body,
            span: start..end,
        })
    }

    fn parse_pattern(&mut self) -> Result<Pattern, ParseError> {
        match self.peek() {
            Some(Token::Underscore) => {
                self.advance();
                Ok(Pattern::Wildcard)
            }
            Some(Token::Integer(n)) => {
                let n = *n;
                self.advance();
                Ok(Pattern::Literal(Literal::Integer(n)))
            }
            Some(Token::Float(n)) => {
                let n = *n;
                self.advance();
                Ok(Pattern::Literal(Literal::Float(n)))
            }
            Some(Token::String(s)) => {
                let s = s.clone();
                self.advance();
                Ok(Pattern::Literal(Literal::String(s)))
            }
            Some(Token::True) => {
                self.advance();
                Ok(Pattern::Literal(Literal::Bool(true)))
            }
            Some(Token::False) => {
                self.advance();
                Ok(Pattern::Literal(Literal::Bool(false)))
            }
            Some(Token::Identifier(name)) => {
                let name = name.clone();
                self.advance();

                // Check for constructor pattern: Okay(inner) or Oops(inner)
                if (name == "Okay" || name == "Oops") && self.check(&Token::LParen) {
                    self.advance(); // consume '('
                    let inner_pattern = if self.check(&Token::RParen) {
                        None
                    } else {
                        Some(Box::new(self.parse_pattern()?))
                    };
                    self.expect(Token::RParen)?;
                    Ok(Pattern::Constructor(name, inner_pattern))
                } else {
                    Ok(Pattern::Identifier(name))
                }
            }
            _ => Err(self.error("Expected pattern")),
        }
    }

    // === Emote Tag ===

    fn parse_emote_tag(&mut self) -> Result<EmoteTag, ParseError> {
        let start = self.current_span().start;
        self.expect(Token::At)?;
        let name = self.expect_identifier()?;

        let params = if self.check(&Token::LParen) {
            self.advance();
            let mut params = Vec::new();
            if !self.check(&Token::RParen) {
                params.push(self.parse_emote_param()?);
                while self.check(&Token::Comma) {
                    self.advance();
                    params.push(self.parse_emote_param()?);
                }
            }
            self.expect(Token::RParen)?;
            params
        } else {
            vec![]
        };

        let end = self.previous_span().end;

        Ok(EmoteTag {
            name,
            params,
            span: start..end,
        })
    }

    fn parse_emote_param(&mut self) -> Result<EmoteParam, ParseError> {
        let name = self.expect_identifier()?;
        self.expect(Token::Equal)?;

        let value = match self.peek() {
            Some(Token::Integer(n)) => {
                let n = *n;
                self.advance();
                EmoteValue::Number(n as f64)
            }
            Some(Token::Float(n)) => {
                let n = *n;
                self.advance();
                EmoteValue::Number(n)
            }
            Some(Token::String(s)) => {
                let s = s.clone();
                self.advance();
                EmoteValue::String(s)
            }
            Some(Token::Identifier(s)) => {
                let s = s.clone();
                self.advance();
                EmoteValue::Identifier(s)
            }
            _ => return Err(self.error("Expected emote parameter value")),
        };

        Ok(EmoteParam { name, value })
    }

    // === Expression Parsing (Pratt parser style) ===

    fn parse_expression(&mut self) -> Result<Spanned<Expr>, ParseError> {
        self.parse_or()
    }

    fn parse_or(&mut self) -> Result<Spanned<Expr>, ParseError> {
        let mut left = self.parse_and()?;

        while self.check(&Token::Or) {
            self.advance();
            let right = self.parse_and()?;
            let span = left.span.start..right.span.end;
            left = Spanned::new(
                Expr::Binary(BinaryOp::Or, Box::new(left), Box::new(right)),
                span,
            );
        }

        Ok(left)
    }

    fn parse_and(&mut self) -> Result<Spanned<Expr>, ParseError> {
        let mut left = self.parse_equality()?;

        while self.check(&Token::And) {
            self.advance();
            let right = self.parse_equality()?;
            let span = left.span.start..right.span.end;
            left = Spanned::new(
                Expr::Binary(BinaryOp::And, Box::new(left), Box::new(right)),
                span,
            );
        }

        Ok(left)
    }

    fn parse_equality(&mut self) -> Result<Spanned<Expr>, ParseError> {
        let mut left = self.parse_comparison()?;

        loop {
            let op = match self.peek() {
                Some(Token::EqualEqual) => BinaryOp::Eq,
                Some(Token::BangEqual) => BinaryOp::NotEq,
                _ => break,
            };
            self.advance();
            let right = self.parse_comparison()?;
            let span = left.span.start..right.span.end;
            left = Spanned::new(Expr::Binary(op, Box::new(left), Box::new(right)), span);
        }

        Ok(left)
    }

    fn parse_comparison(&mut self) -> Result<Spanned<Expr>, ParseError> {
        let mut left = self.parse_additive()?;

        loop {
            let op = match self.peek() {
                Some(Token::Less) => BinaryOp::Lt,
                Some(Token::Greater) => BinaryOp::Gt,
                Some(Token::LessEqual) => BinaryOp::LtEq,
                Some(Token::GreaterEqual) => BinaryOp::GtEq,
                _ => break,
            };
            self.advance();
            let right = self.parse_additive()?;
            let span = left.span.start..right.span.end;
            left = Spanned::new(Expr::Binary(op, Box::new(left), Box::new(right)), span);
        }

        Ok(left)
    }

    fn parse_additive(&mut self) -> Result<Spanned<Expr>, ParseError> {
        let mut left = self.parse_multiplicative()?;

        loop {
            let op = match self.peek() {
                Some(Token::Plus) => BinaryOp::Add,
                Some(Token::Minus) => BinaryOp::Sub,
                _ => break,
            };
            self.advance();
            let right = self.parse_multiplicative()?;
            let span = left.span.start..right.span.end;
            left = Spanned::new(Expr::Binary(op, Box::new(left), Box::new(right)), span);
        }

        Ok(left)
    }

    fn parse_multiplicative(&mut self) -> Result<Spanned<Expr>, ParseError> {
        let mut left = self.parse_unary()?;

        loop {
            let op = match self.peek() {
                Some(Token::Star) => BinaryOp::Mul,
                Some(Token::Slash) => BinaryOp::Div,
                Some(Token::Percent) => BinaryOp::Mod,
                _ => break,
            };
            self.advance();
            let right = self.parse_unary()?;
            let span = left.span.start..right.span.end;
            left = Spanned::new(Expr::Binary(op, Box::new(left), Box::new(right)), span);
        }

        Ok(left)
    }

    fn parse_unary(&mut self) -> Result<Spanned<Expr>, ParseError> {
        match self.peek() {
            Some(Token::Not) => {
                let start = self.current_span().start;
                self.advance();
                let expr = self.parse_unary()?;
                let end = expr.span.end;
                Ok(Spanned::new(
                    Expr::Unary(UnaryOp::Not, Box::new(expr)),
                    start..end,
                ))
            }
            Some(Token::Minus) => {
                let start = self.current_span().start;
                self.advance();
                let expr = self.parse_unary()?;
                let end = expr.span.end;
                Ok(Spanned::new(
                    Expr::Unary(UnaryOp::Neg, Box::new(expr)),
                    start..end,
                ))
            }
            _ => self.parse_postfix(),
        }
    }

    fn parse_postfix(&mut self) -> Result<Spanned<Expr>, ParseError> {
        let mut expr = self.parse_primary()?;

        loop {
            if self.check(&Token::LBracket) {
                // Array/string indexing: expr[index]
                self.advance();
                let index = self.parse_expression()?;
                self.expect(Token::RBracket)?;
                let span = expr.span.start..self.previous_span().end;
                expr = Spanned::new(Expr::Index(Box::new(expr), Box::new(index)), span);
            } else if self.check(&Token::Measured) {
                // Unit measurement: expr measured in unit
                self.advance();
                self.expect(Token::In)?;
                let unit = self.expect_identifier()?;
                let span = expr.span.start..self.previous_span().end;
                expr = Spanned::new(Expr::UnitMeasurement(Box::new(expr), unit), span);
            } else {
                break;
            }
        }

        Ok(expr)
    }

    fn parse_primary(&mut self) -> Result<Spanned<Expr>, ParseError> {
        let start = self.current_span().start;

        match self.peek().cloned() {
            Some(Token::Integer(n)) => {
                self.advance();
                let end = self.previous_span().end;
                Ok(Spanned::new(Expr::Literal(Literal::Integer(n)), start..end))
            }
            Some(Token::Float(n)) => {
                self.advance();
                let end = self.previous_span().end;
                Ok(Spanned::new(Expr::Literal(Literal::Float(n)), start..end))
            }
            Some(Token::String(s)) => {
                self.advance();
                let end = self.previous_span().end;
                Ok(Spanned::new(Expr::Literal(Literal::String(s)), start..end))
            }
            Some(Token::True) => {
                self.advance();
                let end = self.previous_span().end;
                Ok(Spanned::new(Expr::Literal(Literal::Bool(true)), start..end))
            }
            Some(Token::False) => {
                self.advance();
                let end = self.previous_span().end;
                Ok(Spanned::new(
                    Expr::Literal(Literal::Bool(false)),
                    start..end,
                ))
            }
            Some(Token::Thanks) => {
                self.advance();
                self.expect(Token::LParen)?;
                let name = self.expect_string()?;
                self.expect(Token::RParen)?;
                let end = self.previous_span().end;
                Ok(Spanned::new(Expr::GratitudeLiteral(name), start..end))
            }
            Some(Token::LBracket) => {
                self.advance();
                let mut elements = Vec::new();
                if !self.check(&Token::RBracket) {
                    elements.push(self.parse_expression()?);
                    while self.check(&Token::Comma) {
                        self.advance();
                        if self.check(&Token::RBracket) {
                            break;
                        }
                        elements.push(self.parse_expression()?);
                    }
                }
                self.expect(Token::RBracket)?;
                let end = self.previous_span().end;
                Ok(Spanned::new(Expr::Array(elements), start..end))
            }
            Some(Token::LParen) => {
                self.advance();
                let expr = self.parse_expression()?;
                self.expect(Token::RParen)?;
                Ok(expr)
            }
            Some(Token::Identifier(name)) => {
                self.advance();
                if self.check(&Token::LParen) {
                    self.advance();

                    // Check for Result constructors: Okay(expr), Oops(expr)
                    if name == "Okay" || name == "Oops" {
                        let inner = self.parse_expression()?;
                        self.expect(Token::RParen)?;
                        let end = self.previous_span().end;
                        let expr = if name == "Okay" {
                            Expr::Okay(Box::new(inner))
                        } else {
                            Expr::Oops(Box::new(inner))
                        };
                        return Ok(Spanned::new(expr, start..end));
                    }

                    // Regular function call
                    let mut args = Vec::new();
                    if !self.check(&Token::RParen) {
                        args.push(self.parse_expression()?);
                        while self.check(&Token::Comma) {
                            self.advance();
                            args.push(self.parse_expression()?);
                        }
                    }
                    self.expect(Token::RParen)?;
                    let end = self.previous_span().end;
                    Ok(Spanned::new(Expr::Call(name, args), start..end))
                } else {
                    let end = self.previous_span().end;
                    Ok(Spanned::new(Expr::Identifier(name), start..end))
                }
            }
            _ => Err(self.error("Expected expression")),
        }
    }

    // === Helper Methods ===

    fn peek(&self) -> Option<&Token> {
        self.tokens.get(self.pos).map(|t| &t.value)
    }

    fn check(&self, token: &Token) -> bool {
        match (self.peek(), token) {
            (Some(Token::Identifier(_)), Token::Identifier(_)) => true,
            (Some(a), b) => std::mem::discriminant(a) == std::mem::discriminant(b),
            _ => false,
        }
    }

    fn advance(&mut self) -> Option<&Token> {
        if !self.is_at_end() {
            self.pos += 1;
        }
        self.tokens.get(self.pos - 1).map(|t| &t.value)
    }

    fn expect(&mut self, token: Token) -> Result<(), ParseError> {
        if self.check(&token) {
            self.advance();
            Ok(())
        } else {
            let found = self
                .peek()
                .map(|t| t.to_string())
                .unwrap_or_else(|| "EOF".to_string());
            Err(ParseError::UnexpectedToken {
                expected: token.to_string(),
                found,
                src: self.source.to_string(),
                span: self.current_span().into(),
            })
        }
    }

    fn expect_identifier(&mut self) -> Result<String, ParseError> {
        match self.peek().cloned() {
            Some(Token::Identifier(name)) => {
                self.advance();
                Ok(name)
            }
            _ => {
                let found = self
                    .peek()
                    .map(|t| t.to_string())
                    .unwrap_or_else(|| "EOF".to_string());
                Err(ParseError::UnexpectedToken {
                    expected: "identifier".to_string(),
                    found,
                    src: self.source.to_string(),
                    span: self.current_span().into(),
                })
            }
        }
    }

    fn expect_string(&mut self) -> Result<String, ParseError> {
        match self.peek().cloned() {
            Some(Token::String(s)) => {
                self.advance();
                Ok(s)
            }
            _ => {
                let found = self
                    .peek()
                    .map(|t| t.to_string())
                    .unwrap_or_else(|| "EOF".to_string());
                Err(ParseError::UnexpectedToken {
                    expected: "string".to_string(),
                    found,
                    src: self.source.to_string(),
                    span: self.current_span().into(),
                })
            }
        }
    }

    fn is_at_end(&self) -> bool {
        matches!(self.peek(), Some(Token::Eof) | None)
    }

    fn current_span(&self) -> std::ops::Range<usize> {
        self.tokens
            .get(self.pos)
            .map(|t| t.span.clone())
            .unwrap_or(0..0)
    }

    fn previous_span(&self) -> std::ops::Range<usize> {
        if self.pos > 0 {
            self.tokens
                .get(self.pos - 1)
                .map(|t| t.span.clone())
                .unwrap_or(0..0)
        } else {
            0..0
        }
    }

    fn error(&self, message: &str) -> ParseError {
        ParseError::General {
            message: message.to_string(),
            src: self.source.to_string(),
            span: self.current_span().into(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::lexer::Lexer;

    fn parse(source: &str) -> Result<Program, ParseError> {
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().expect("Lexer failed");
        let mut parser = Parser::new(tokens, source);
        parser.parse()
    }

    #[test]
    fn test_parse_simple_function() {
        let source = r#"to greet() {
            give back "Hello";
        }"#;
        let program = parse(source).unwrap();
        assert_eq!(program.items.len(), 1);
        assert!(matches!(program.items[0], TopLevelItem::Function(_)));
    }

    #[test]
    fn test_parse_function_with_params() {
        let source = r#"to add(a: Int, b: Int) -> Int {
            give back a + b;
        }"#;
        let program = parse(source).unwrap();
        if let TopLevelItem::Function(f) = &program.items[0] {
            assert_eq!(f.name, "add");
            assert_eq!(f.params.len(), 2);
        }
    }

    #[test]
    fn test_parse_gratitude() {
        let source = r#"thanks to {
            "Rust" -> "For being awesome";
        }"#;
        let program = parse(source).unwrap();
        assert!(matches!(program.items[0], TopLevelItem::GratitudeDecl(_)));
    }

    #[test]
    fn test_parse_consent_block() {
        let source = r#"only if okay "camera" {
            remember x = 1;
        }"#;
        let program = parse(source).unwrap();
        assert!(matches!(program.items[0], TopLevelItem::ConsentBlock(_)));
    }

    #[test]
    fn test_parse_worker() {
        let source = r#"worker background {
            remember x = compute();
        }"#;
        let program = parse(source).unwrap();
        assert!(matches!(program.items[0], TopLevelItem::WorkerDef(_)));
    }

    #[test]
    fn test_parse_expressions() {
        let source = r#"to test() {
            remember x = 1 + 2 * 3;
            remember y = (1 + 2) * 3;
            remember z = a and b or c;
        }"#;
        let program = parse(source).unwrap();
        assert!(matches!(program.items[0], TopLevelItem::Function(_)));
    }
}
