mod token;

pub use token::Token;

use logos::Logos;
use miette::{Diagnostic, SourceSpan};
use thiserror::Error;

#[derive(Error, Debug, Diagnostic)]
#[error("Unexpected character")]
#[diagnostic(code(wokelang::lexer::unexpected_char))]
pub struct LexerError {
    #[source_code]
    pub src: String,
    #[label("here")]
    pub span: SourceSpan,
}

#[derive(Debug, Clone)]
pub struct Spanned<T> {
    pub value: T,
    pub span: std::ops::Range<usize>,
}

impl<T> Spanned<T> {
    pub fn new(value: T, span: std::ops::Range<usize>) -> Self {
        Self { value, span }
    }
}

pub struct Lexer<'src> {
    source: &'src str,
}

impl<'src> Lexer<'src> {
    pub fn new(source: &'src str) -> Self {
        Self { source }
    }

    pub fn tokenize(&self) -> Result<Vec<Spanned<Token>>, LexerError> {
        let mut tokens = Vec::new();
        let mut lexer = Token::lexer(self.source);

        while let Some(result) = lexer.next() {
            match result {
                Ok(token) => {
                    tokens.push(Spanned::new(token, lexer.span()));
                }
                Err(_) => {
                    return Err(LexerError {
                        src: self.source.to_string(),
                        span: lexer.span().into(),
                    });
                }
            }
        }

        tokens.push(Spanned::new(Token::Eof, self.source.len()..self.source.len()));
        Ok(tokens)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_simple_function() {
        let source = r#"to greet() {
            hello "Starting greet";
            give back "Hello, World!";
            goodbye "Ending greet";
        }"#;

        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();

        assert!(matches!(tokens[0].value, Token::To));
        assert!(matches!(tokens[1].value, Token::Identifier(_)));
    }

    #[test]
    fn test_consent_block() {
        let source = r#"only if okay "access_camera" { }"#;

        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();

        assert!(matches!(tokens[0].value, Token::Only));
        assert!(matches!(tokens[1].value, Token::If));
        assert!(matches!(tokens[2].value, Token::Okay));
    }

    #[test]
    fn test_numbers() {
        let source = "42 3.14 -17";

        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();

        assert!(matches!(tokens[0].value, Token::Integer(42)));
        assert!(matches!(tokens[1].value, Token::Float(_)));
        assert!(matches!(tokens[2].value, Token::Minus));
        assert!(matches!(tokens[3].value, Token::Integer(17)));
    }

    #[test]
    fn test_emote_tag() {
        let source = "@happy(intensity=10)";

        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();

        assert!(matches!(tokens[0].value, Token::At));
        assert!(matches!(tokens[1].value, Token::Identifier(_)));
    }
}
