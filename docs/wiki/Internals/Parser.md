# Parser Internals

The parser transforms a stream of tokens into an Abstract Syntax Tree (AST).

---

## Overview

WokeLang uses a hand-written **recursive descent parser** with **Pratt parsing** for expressions. This approach provides:

- Clear, maintainable code
- Excellent error messages
- Fine-grained control over parsing

---

## Parser Structure

Located in `src/parser/mod.rs`:

```rust
pub struct Parser<'a> {
    tokens: Vec<Spanned<Token>>,
    source: &'a str,
    current: usize,
}

impl<'a> Parser<'a> {
    pub fn new(tokens: Vec<Spanned<Token>>, source: &'a str) -> Self {
        Self {
            tokens,
            source,
            current: 0,
        }
    }

    pub fn parse(&mut self) -> Result<Program> {
        let mut items = Vec::new();

        while !self.is_at_end() {
            items.push(self.parse_top_level_item()?);
        }

        Ok(Program { items })
    }
}
```

---

## Parsing Entry Points

### Top-Level Items

```rust
fn parse_top_level_item(&mut self) -> Result<TopLevelItem> {
    // Check for emote tag
    let emote = if self.check(Token::At) {
        Some(self.parse_emote_tag()?)
    } else {
        None
    };

    match self.peek().0 {
        Token::To => {
            let mut func = self.parse_function()?;
            func.emote = emote;
            Ok(TopLevelItem::Function(func))
        }
        Token::Worker => Ok(TopLevelItem::Worker(self.parse_worker()?)),
        Token::Side => Ok(TopLevelItem::SideQuest(self.parse_side_quest()?)),
        Token::Type => Ok(TopLevelItem::TypeDef(self.parse_type_def()?)),
        Token::Thanks => Ok(TopLevelItem::GratitudeBlock(self.parse_gratitude()?)),
        Token::Hash => Ok(TopLevelItem::Pragma(self.parse_pragma()?)),
        Token::Use => Ok(TopLevelItem::Import(self.parse_import()?)),
        _ => Err(self.error("Expected top-level declaration")),
    }
}
```

### Function Parsing

```rust
fn parse_function(&mut self) -> Result<Function> {
    self.expect(Token::To)?;

    let name = self.expect_identifier()?;

    self.expect(Token::LeftParen)?;
    let params = self.parse_param_list()?;
    self.expect(Token::RightParen)?;

    let return_type = if self.match_token(Token::Arrow) || self.match_token(Token::ArrowAscii) {
        Some(self.parse_type()?)
    } else {
        None
    };

    self.expect(Token::LeftBrace)?;

    // Parse optional hello
    let hello = if self.check(Token::Hello) {
        self.advance();
        let msg = self.expect_string()?;
        self.expect(Token::Semicolon)?;
        Some(msg)
    } else {
        None
    };

    // Parse body statements
    let body = self.parse_block_contents()?;

    // Parse optional goodbye
    let goodbye = if self.check(Token::Goodbye) {
        self.advance();
        let msg = self.expect_string()?;
        self.expect(Token::Semicolon)?;
        Some(msg)
    } else {
        None
    };

    self.expect(Token::RightBrace)?;

    Ok(Function {
        name,
        params,
        return_type,
        hello,
        body,
        goodbye,
        emote: None,
    })
}
```

---

## Statement Parsing

```rust
fn parse_statement(&mut self) -> Result<Statement> {
    match self.peek().0 {
        Token::Remember => self.parse_remember(),
        Token::When => self.parse_when(),
        Token::Repeat => self.parse_repeat(),
        Token::Give => self.parse_return(),
        Token::Attempt => self.parse_attempt(),
        Token::Only => self.parse_consent(),
        Token::Complain => self.parse_complain(),
        Token::Decide => self.parse_decide(),
        Token::Hello => self.parse_hello(),
        Token::Goodbye => self.parse_goodbye(),
        _ => self.parse_expression_statement(),
    }
}
```

### Variable Declaration

```rust
fn parse_remember(&mut self) -> Result<Statement> {
    self.expect(Token::Remember)?;

    let name = self.expect_identifier()?;

    // Optional type annotation
    let type_ann = if self.match_token(Token::Colon) {
        Some(self.parse_type()?)
    } else {
        None
    };

    self.expect(Token::Equal)?;
    let value = self.parse_expression()?;

    // Optional unit
    let unit = if self.match_token(Token::Measured) {
        self.expect(Token::In)?;
        Some(self.expect_identifier()?)
    } else {
        None
    };

    self.expect(Token::Semicolon)?;

    Ok(Statement::Remember { name, type_ann, value, unit })
}
```

### Conditional Statement

```rust
fn parse_when(&mut self) -> Result<Statement> {
    self.expect(Token::When)?;

    let condition = self.parse_expression()?;

    self.expect(Token::LeftBrace)?;
    let then_block = self.parse_block_contents()?;
    self.expect(Token::RightBrace)?;

    let else_block = if self.match_token(Token::Otherwise) {
        self.expect(Token::LeftBrace)?;
        let block = self.parse_block_contents()?;
        self.expect(Token::RightBrace)?;
        Some(block)
    } else {
        None
    };

    Ok(Statement::When { condition, then_block, else_block })
}
```

---

## Expression Parsing (Pratt/Precedence Climbing)

### Operator Precedence

```
Lowest                              Highest
  |                                    |
  v                                    v
  or → and → == != → < > <= >= → + - → * / % → not - (unary) → call, index
```

### Implementation

```rust
fn parse_expression(&mut self) -> Result<Expr> {
    self.parse_or_expr()
}

fn parse_or_expr(&mut self) -> Result<Expr> {
    let mut left = self.parse_and_expr()?;

    while self.match_token(Token::Or) {
        let right = self.parse_and_expr()?;
        left = Expr::Binary {
            left: Box::new(left),
            op: BinOp::Or,
            right: Box::new(right),
        };
    }

    Ok(left)
}

fn parse_and_expr(&mut self) -> Result<Expr> {
    let mut left = self.parse_equality_expr()?;

    while self.match_token(Token::And) {
        let right = self.parse_equality_expr()?;
        left = Expr::Binary {
            left: Box::new(left),
            op: BinOp::And,
            right: Box::new(right),
        };
    }

    Ok(left)
}

fn parse_equality_expr(&mut self) -> Result<Expr> {
    let mut left = self.parse_comparison_expr()?;

    while let Some(op) = self.match_equality_op() {
        let right = self.parse_comparison_expr()?;
        left = Expr::Binary {
            left: Box::new(left),
            op,
            right: Box::new(right),
        };
    }

    Ok(left)
}

fn parse_comparison_expr(&mut self) -> Result<Expr> {
    let mut left = self.parse_additive_expr()?;

    while let Some(op) = self.match_comparison_op() {
        let right = self.parse_additive_expr()?;
        left = Expr::Binary {
            left: Box::new(left),
            op,
            right: Box::new(right),
        };
    }

    Ok(left)
}

fn parse_additive_expr(&mut self) -> Result<Expr> {
    let mut left = self.parse_multiplicative_expr()?;

    while let Some(op) = self.match_additive_op() {
        let right = self.parse_multiplicative_expr()?;
        left = Expr::Binary {
            left: Box::new(left),
            op,
            right: Box::new(right),
        };
    }

    Ok(left)
}

fn parse_multiplicative_expr(&mut self) -> Result<Expr> {
    let mut left = self.parse_unary_expr()?;

    while let Some(op) = self.match_multiplicative_op() {
        let right = self.parse_unary_expr()?;
        left = Expr::Binary {
            left: Box::new(left),
            op,
            right: Box::new(right),
        };
    }

    Ok(left)
}

fn parse_unary_expr(&mut self) -> Result<Expr> {
    if self.match_token(Token::Not) {
        let operand = self.parse_unary_expr()?;
        return Ok(Expr::Unary {
            op: UnaryOp::Not,
            operand: Box::new(operand),
        });
    }

    if self.match_token(Token::Minus) {
        let operand = self.parse_unary_expr()?;
        return Ok(Expr::Unary {
            op: UnaryOp::Neg,
            operand: Box::new(operand),
        });
    }

    self.parse_postfix_expr()
}

fn parse_postfix_expr(&mut self) -> Result<Expr> {
    let mut expr = self.parse_primary()?;

    loop {
        if self.match_token(Token::LeftParen) {
            // Function call
            let args = self.parse_argument_list()?;
            self.expect(Token::RightParen)?;

            if let Expr::Identifier(name) = expr {
                expr = Expr::Call { function: name, args };
            } else {
                return Err(self.error("Expected function name"));
            }
        } else if self.match_token(Token::LeftBracket) {
            // Array index
            let index = self.parse_expression()?;
            self.expect(Token::RightBracket)?;
            expr = Expr::Index {
                array: Box::new(expr),
                index: Box::new(index),
            };
        } else if self.match_token(Token::Dot) {
            // Field access
            let field = self.expect_identifier()?;
            expr = Expr::FieldAccess {
                object: Box::new(expr),
                field,
            };
        } else {
            break;
        }
    }

    Ok(expr)
}
```

### Primary Expressions

```rust
fn parse_primary(&mut self) -> Result<Expr> {
    let token = self.advance();

    match token.0 {
        Token::Integer(n) => Ok(Expr::Literal(Literal::Int(n))),
        Token::Float(f) => Ok(Expr::Literal(Literal::Float(f))),
        Token::String(s) => Ok(Expr::Literal(Literal::String(s))),
        Token::True => Ok(Expr::Literal(Literal::Bool(true))),
        Token::False => Ok(Expr::Literal(Literal::Bool(false))),
        Token::Identifier(name) => Ok(Expr::Identifier(name)),
        Token::LeftParen => {
            let expr = self.parse_expression()?;
            self.expect(Token::RightParen)?;
            Ok(expr)
        }
        Token::LeftBracket => {
            let elements = self.parse_array_elements()?;
            self.expect(Token::RightBracket)?;
            Ok(Expr::Array(elements))
        }
        Token::Thanks => {
            self.expect(Token::LeftParen)?;
            let msg = self.expect_string()?;
            self.expect(Token::RightParen)?;
            Ok(Expr::Gratitude(msg))
        }
        _ => Err(self.error("Expected expression")),
    }
}
```

---

## Helper Methods

```rust
impl<'a> Parser<'a> {
    /// Check if at end of tokens
    fn is_at_end(&self) -> bool {
        self.current >= self.tokens.len()
    }

    /// Peek at current token without consuming
    fn peek(&self) -> &Spanned<Token> {
        &self.tokens[self.current]
    }

    /// Advance and return current token
    fn advance(&mut self) -> Spanned<Token> {
        if !self.is_at_end() {
            self.current += 1;
        }
        self.tokens[self.current - 1].clone()
    }

    /// Check if current token matches
    fn check(&self, expected: Token) -> bool {
        if self.is_at_end() {
            return false;
        }
        std::mem::discriminant(&self.peek().0) == std::mem::discriminant(&expected)
    }

    /// Consume token if it matches
    fn match_token(&mut self, expected: Token) -> bool {
        if self.check(expected) {
            self.advance();
            true
        } else {
            false
        }
    }

    /// Expect a specific token or error
    fn expect(&mut self, expected: Token) -> Result<Spanned<Token>> {
        if self.check(expected.clone()) {
            Ok(self.advance())
        } else {
            Err(self.error(&format!("Expected {:?}", expected)))
        }
    }

    /// Expect an identifier
    fn expect_identifier(&mut self) -> Result<String> {
        match self.advance().0 {
            Token::Identifier(name) => Ok(name),
            _ => Err(self.error("Expected identifier")),
        }
    }

    /// Create an error at current position
    fn error(&self, message: &str) -> ParseError {
        let span = if self.is_at_end() {
            self.tokens.last().map(|t| t.1.clone()).unwrap_or(0..0)
        } else {
            self.peek().1.clone()
        };

        ParseError {
            message: message.to_string(),
            span,
        }
    }
}
```

---

## Error Recovery

The parser can recover from errors to report multiple issues:

```rust
fn synchronize(&mut self) {
    self.advance();

    while !self.is_at_end() {
        // Synchronize at statement boundaries
        if self.previous().0 == Token::Semicolon {
            return;
        }

        // Synchronize at declaration keywords
        match self.peek().0 {
            Token::To
            | Token::Remember
            | Token::When
            | Token::Repeat
            | Token::Give
            | Token::Worker
            | Token::Type => return,
            _ => {}
        }

        self.advance();
    }
}
```

---

## Testing

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use crate::lexer::Lexer;

    fn parse(source: &str) -> Result<Program> {
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens, source);
        parser.parse()
    }

    #[test]
    fn test_function() {
        let result = parse("to add(a: Int, b: Int) → Int { give back a + b; }");
        assert!(result.is_ok());

        let program = result.unwrap();
        assert_eq!(program.items.len(), 1);

        if let TopLevelItem::Function(f) = &program.items[0] {
            assert_eq!(f.name, "add");
            assert_eq!(f.params.len(), 2);
        } else {
            panic!("Expected function");
        }
    }

    #[test]
    fn test_expression_precedence() {
        let result = parse("to main() { remember x = 2 + 3 * 4; }");
        assert!(result.is_ok());

        // Should parse as 2 + (3 * 4), not (2 + 3) * 4
    }

    #[test]
    fn test_when_otherwise() {
        let result = parse(r#"
            to main() {
                when x > 0 {
                    print("positive");
                } otherwise {
                    print("non-positive");
                }
            }
        "#);
        assert!(result.is_ok());
    }
}
```

---

## Grammar Correspondence

The parser implements the EBNF grammar in `grammar/wokelang.ebnf`:

| Grammar Rule | Parser Method |
|-------------|---------------|
| `program` | `parse()` |
| `top_level_item` | `parse_top_level_item()` |
| `function_def` | `parse_function()` |
| `statement` | `parse_statement()` |
| `expression` | `parse_expression()` |
| `primary` | `parse_primary()` |

---

## Next Steps

- [AST Structure](AST.md)
- [Interpreter Internals](Interpreter.md)
- [Grammar Reference](../../grammar/wokelang.ebnf)
