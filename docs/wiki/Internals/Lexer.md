# Lexer Internals

The lexer (tokenizer) converts WokeLang source code into a stream of tokens for the parser.

---

## Overview

WokeLang uses the [`logos`](https://github.com/maciejhirsz/logos) crate for lexer generation. Logos is a fast, zero-copy lexer generator that creates efficient state machines from declarative token definitions.

---

## Token Types

Located in `src/lexer/token.rs`:

```rust
#[derive(Logos, Debug, Clone, PartialEq)]
#[logos(skip r"[ \t\n\r]+")]  // Skip whitespace
pub enum Token {
    // === Keywords: Control Flow ===
    #[token("to")]
    To,

    #[token("give")]
    Give,

    #[token("back")]
    Back,

    #[token("remember")]
    Remember,

    #[token("when")]
    When,

    #[token("otherwise")]
    Otherwise,

    #[token("repeat")]
    Repeat,

    #[token("times")]
    Times,

    // === Keywords: Consent & Safety ===
    #[token("only")]
    Only,

    #[token("if")]
    If,

    #[token("okay")]
    Okay,

    #[token("attempt")]
    Attempt,

    #[token("safely")]
    Safely,

    #[token("or")]
    Or,

    #[token("reassure")]
    Reassure,

    #[token("complain")]
    Complain,

    // === Keywords: Gratitude ===
    #[token("thanks")]
    Thanks,

    // === Keywords: Lifecycle ===
    #[token("hello")]
    Hello,

    #[token("goodbye")]
    Goodbye,

    // === Keywords: Concurrency ===
    #[token("worker")]
    Worker,

    #[token("side")]
    Side,

    #[token("quest")]
    Quest,

    #[token("superpower")]
    Superpower,

    #[token("spawn")]
    Spawn,

    // === Keywords: Pattern Matching ===
    #[token("decide")]
    Decide,

    #[token("based")]
    Based,

    #[token("on")]
    On,

    // === Keywords: Units ===
    #[token("measured")]
    Measured,

    #[token("in")]
    In,

    // === Keywords: Types ===
    #[token("type")]
    Type,

    #[token("const")]
    Const,

    #[token("Maybe")]
    Maybe,

    // === Keywords: Boolean ===
    #[token("true")]
    True,

    #[token("false")]
    False,

    #[token("and")]
    And,

    #[token("not")]
    Not,

    // === Keywords: Modules ===
    #[token("use")]
    Use,

    #[token("renamed")]
    Renamed,

    #[token("share")]
    Share,

    // === Literals ===
    #[regex(r"-?[0-9]+", |lex| lex.slice().parse().ok())]
    Integer(i64),

    #[regex(r"-?[0-9]+\.[0-9]+", |lex| lex.slice().parse().ok())]
    Float(f64),

    #[regex(r#""([^"\\]|\\.)*""#, |lex| {
        let s = lex.slice();
        Some(s[1..s.len()-1].to_string())  // Remove quotes
    })]
    String(String),

    // === Identifiers ===
    #[regex(r"[a-zA-Z_][a-zA-Z0-9_]*", |lex| lex.slice().to_string())]
    Identifier(String),

    // === Operators ===
    #[token("+")]
    Plus,

    #[token("-")]
    Minus,

    #[token("*")]
    Star,

    #[token("/")]
    Slash,

    #[token("%")]
    Percent,

    #[token("==")]
    EqualEqual,

    #[token("!=")]
    BangEqual,

    #[token("<")]
    Less,

    #[token(">")]
    Greater,

    #[token("<=")]
    LessEqual,

    #[token(">=")]
    GreaterEqual,

    // === Punctuation ===
    #[token("(")]
    LeftParen,

    #[token(")")]
    RightParen,

    #[token("{")]
    LeftBrace,

    #[token("}")]
    RightBrace,

    #[token("[")]
    LeftBracket,

    #[token("]")]
    RightBracket,

    #[token(",")]
    Comma,

    #[token(";")]
    Semicolon,

    #[token(":")]
    Colon,

    #[token("=")]
    Equal,

    #[token("→")]
    Arrow,

    #[token("->")]
    ArrowAscii,

    #[token("@")]
    At,

    #[token("#")]
    Hash,

    #[token(".")]
    Dot,

    #[token("&")]
    Ampersand,

    #[token("|")]
    Pipe,

    #[token("_")]
    Underscore,

    // === Comments ===
    #[regex(r"//[^\n]*", logos::skip)]
    LineComment,

    #[regex(r"/\*([^*]|\*[^/])*\*/", logos::skip)]
    BlockComment,
}
```

---

## Lexer Implementation

Located in `src/lexer/mod.rs`:

```rust
pub mod token;

use logos::Logos;
use std::ops::Range;

pub use token::Token;

/// A token with its source location
pub type Spanned<T> = (T, Range<usize>);

/// The WokeLang lexer
pub struct Lexer<'source> {
    source: &'source str,
}

impl<'source> Lexer<'source> {
    /// Create a new lexer for the given source code
    pub fn new(source: &'source str) -> Self {
        Self { source }
    }

    /// Tokenize the source code into a vector of spanned tokens
    pub fn tokenize(&self) -> Result<Vec<Spanned<Token>>, LexError> {
        let mut tokens = Vec::new();
        let mut lexer = Token::lexer(self.source);

        while let Some(result) = lexer.next() {
            match result {
                Ok(token) => {
                    tokens.push((token, lexer.span()));
                }
                Err(_) => {
                    return Err(LexError {
                        message: format!(
                            "Unexpected character: '{}'",
                            &self.source[lexer.span()]
                        ),
                        span: lexer.span(),
                    });
                }
            }
        }

        Ok(tokens)
    }
}

#[derive(Debug)]
pub struct LexError {
    pub message: String,
    pub span: Range<usize>,
}
```

---

## Tokenization Process

### 1. Input Processing

```
Source: "remember x = 42;"
         ^^^^^^^^ ^ ^ ^^^
         |        | | |
         |        | | Integer(42), Semicolon
         |        | Equal
         |        Identifier("x")
         Remember
```

### 2. Token Stream Output

```rust
vec![
    (Token::Remember, 0..8),
    (Token::Identifier("x".to_string()), 9..10),
    (Token::Equal, 11..12),
    (Token::Integer(42), 13..15),
    (Token::Semicolon, 15..16),
]
```

### 3. Span Information

Each token includes its byte range in the source:

```rust
pub type Spanned<T> = (T, Range<usize>);

// Example: "remember" at bytes 0-8
(Token::Remember, 0..8)
```

This enables accurate error reporting with source locations.

---

## Special Cases

### Unicode Arrow

WokeLang supports both Unicode and ASCII arrows:

```rust
#[token("→")]
Arrow,

#[token("->")]
ArrowAscii,
```

Both are valid:
```wokelang
to add(a: Int, b: Int) → Int { ... }   // Unicode
to add(a: Int, b: Int) -> Int { ... }  // ASCII
```

### String Escapes

Strings handle escape sequences:

```rust
#[regex(r#""([^"\\]|\\.)*""#, |lex| {
    let s = lex.slice();
    Some(s[1..s.len()-1].to_string())
})]
String(String),
```

Supported escapes:
- `\n` - newline
- `\t` - tab
- `\r` - carriage return
- `\"` - escaped quote
- `\\` - escaped backslash

### Comments

Comments are skipped automatically:

```rust
#[regex(r"//[^\n]*", logos::skip)]
LineComment,

#[regex(r"/\*([^*]|\*[^/])*\*/", logos::skip)]
BlockComment,
```

---

## Error Handling

When the lexer encounters an unexpected character:

```rust
Err(_) => {
    return Err(LexError {
        message: format!(
            "Unexpected character: '{}'",
            &self.source[lexer.span()]
        ),
        span: lexer.span(),
    });
}
```

Example error:

```
Error: Lexer error at 1:5
  |
1 | let $ = 5;
  |     ^ Unexpected character: '$'
```

---

## Testing

Tests are located in `src/lexer/mod.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_keywords() {
        let lexer = Lexer::new("to remember when otherwise");
        let tokens = lexer.tokenize().unwrap();

        assert_eq!(tokens[0].0, Token::To);
        assert_eq!(tokens[1].0, Token::Remember);
        assert_eq!(tokens[2].0, Token::When);
        assert_eq!(tokens[3].0, Token::Otherwise);
    }

    #[test]
    fn test_literals() {
        let lexer = Lexer::new("42 3.14 \"hello\" true false");
        let tokens = lexer.tokenize().unwrap();

        assert_eq!(tokens[0].0, Token::Integer(42));
        assert_eq!(tokens[1].0, Token::Float(3.14));
        assert_eq!(tokens[2].0, Token::String("hello".to_string()));
        assert_eq!(tokens[3].0, Token::True);
        assert_eq!(tokens[4].0, Token::False);
    }

    #[test]
    fn test_operators() {
        let lexer = Lexer::new("+ - * / % == != < > <= >=");
        let tokens = lexer.tokenize().unwrap();

        assert_eq!(tokens[0].0, Token::Plus);
        assert_eq!(tokens[1].0, Token::Minus);
        // ...
    }
}
```

---

## Performance

Logos generates efficient lexers:

- **Zero-copy**: Uses slices into source
- **State machine**: Compiled to efficient DFA
- **No allocations**: Until string extraction

Benchmark (approximate):
- ~100 MB/s on typical source code
- O(n) linear time complexity

---

## Future Enhancements

### v0.3.0 Planned
- Unicode identifiers
- Heredoc strings (`"""..."""`)
- Raw strings (`r"..."`)

### v0.4.0 Planned
- String interpolation (`"Hello, ${name}!"`)

### v0.5.0 Planned
- Custom operators

---

## Next Steps

- [Parser Internals](Parser.md)
- [AST Structure](AST.md)
- [Token Reference](../Reference/Keywords.md)
