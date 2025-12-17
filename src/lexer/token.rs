use logos::Logos;

fn parse_string(lex: &mut logos::Lexer<Token>) -> Option<String> {
    let slice = lex.slice();
    // Remove surrounding quotes and handle escape sequences
    let inner = &slice[1..slice.len() - 1];
    let mut result = String::new();
    let mut chars = inner.chars().peekable();

    while let Some(c) = chars.next() {
        if c == '\\' {
            match chars.next() {
                Some('n') => result.push('\n'),
                Some('t') => result.push('\t'),
                Some('r') => result.push('\r'),
                Some('"') => result.push('"'),
                Some('\'') => result.push('\''),
                Some('\\') => result.push('\\'),
                _ => return None,
            }
        } else {
            result.push(c);
        }
    }

    Some(result)
}

#[derive(Logos, Debug, Clone, PartialEq)]
#[logos(skip r"[ \t\n\r\f]+")]
#[logos(skip r"//[^\n]*")]
#[logos(skip r"/\*[^*]*\*+(?:[^/*][^*]*\*+)*/")]
pub enum Token {
    // === Keywords - Control Flow ===
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

    // === Keywords - Consent & Safety ===
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

    #[token("reassure")]
    Reassure,

    #[token("complain")]
    Complain,

    // === Keywords - Gratitude ===
    #[token("thanks")]
    Thanks,

    // === Keywords - Lifecycle ===
    #[token("hello")]
    Hello,

    #[token("goodbye")]
    Goodbye,

    // === Keywords - Concurrency ===
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

    #[token("send")]
    Send,

    #[token("receive")]
    Receive,

    #[token("channel")]
    Channel,

    #[token("await")]
    Await,

    #[token("cancel")]
    Cancel,

    #[token("from")]
    From,

    // === Keywords - Pattern Matching ===
    #[token("decide")]
    Decide,

    #[token("based")]
    Based,

    #[token("on")]
    On,

    // === Keywords - Units ===
    #[token("measured")]
    Measured,

    #[token("in")]
    In,

    // === Keywords - Module ===
    #[token("use")]
    Use,

    #[token("renamed")]
    Renamed,

    #[token("share")]
    Share,

    // === Keywords - Types ===
    #[token("type")]
    Type,

    #[token("const")]
    Const,

    #[token("String")]
    TypeString,

    #[token("Int")]
    TypeInt,

    #[token("Float")]
    TypeFloat,

    #[token("Bool")]
    TypeBool,

    #[token("Maybe")]
    Maybe,

    // === Keywords - Constraints ===
    #[token("must")]
    Must,

    #[token("have")]
    Have,

    // === Keywords - Pragmas ===
    #[token("care")]
    Care,

    #[token("strict")]
    Strict,

    #[token("verbose")]
    Verbose,

    // === Keywords - Boolean ===
    #[token("true")]
    True,

    #[token("false")]
    False,

    #[token("and")]
    And,

    #[token("or")]
    Or,

    #[token("not")]
    Not,

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

    #[token("=")]
    Equal,

    #[token("→")]
    Arrow,

    #[token("->")]
    AsciiArrow,

    // === Delimiters ===
    #[token("(")]
    LParen,

    #[token(")")]
    RParen,

    #[token("{")]
    LBrace,

    #[token("}")]
    RBrace,

    #[token("[")]
    LBracket,

    #[token("]")]
    RBracket,

    #[token(",")]
    Comma,

    #[token(";")]
    Semicolon,

    #[token(":")]
    Colon,

    #[token(".")]
    Dot,

    #[token("@")]
    At,

    #[token("&")]
    Ampersand,

    #[token("|")]
    Pipe,

    #[token("#")]
    Hash,

    #[token("_")]
    Underscore,

    #[token("?")]
    Question,

    // === Keywords - Result Types ===
    #[token("Okay")]
    OkayType,

    #[token("Oops")]
    Oops,

    #[token("unwrap")]
    Unwrap,

    // === Literals ===
    #[regex(r"[0-9]+", |lex| lex.slice().parse::<i64>().ok())]
    Integer(i64),

    #[regex(r"[0-9]+\.[0-9]+", |lex| lex.slice().parse::<f64>().ok())]
    Float(f64),

    #[regex(r#""([^"\\]|\\.)*""#, parse_string)]
    String(String),

    // === Identifiers ===
    #[regex(r"[a-zA-Z][a-zA-Z0-9_]*", |lex| lex.slice().to_string())]
    Identifier(String),

    // === Special ===
    Eof,
}

impl std::fmt::Display for Token {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Token::To => write!(f, "to"),
            Token::Give => write!(f, "give"),
            Token::Back => write!(f, "back"),
            Token::Remember => write!(f, "remember"),
            Token::When => write!(f, "when"),
            Token::Otherwise => write!(f, "otherwise"),
            Token::Repeat => write!(f, "repeat"),
            Token::Times => write!(f, "times"),
            Token::Only => write!(f, "only"),
            Token::If => write!(f, "if"),
            Token::Okay => write!(f, "okay"),
            Token::Attempt => write!(f, "attempt"),
            Token::Safely => write!(f, "safely"),
            Token::Reassure => write!(f, "reassure"),
            Token::Complain => write!(f, "complain"),
            Token::Thanks => write!(f, "thanks"),
            Token::Hello => write!(f, "hello"),
            Token::Goodbye => write!(f, "goodbye"),
            Token::Worker => write!(f, "worker"),
            Token::Side => write!(f, "side"),
            Token::Quest => write!(f, "quest"),
            Token::Superpower => write!(f, "superpower"),
            Token::Spawn => write!(f, "spawn"),
            Token::Send => write!(f, "send"),
            Token::Receive => write!(f, "receive"),
            Token::Channel => write!(f, "channel"),
            Token::Await => write!(f, "await"),
            Token::Cancel => write!(f, "cancel"),
            Token::From => write!(f, "from"),
            Token::Decide => write!(f, "decide"),
            Token::Based => write!(f, "based"),
            Token::On => write!(f, "on"),
            Token::Measured => write!(f, "measured"),
            Token::In => write!(f, "in"),
            Token::Use => write!(f, "use"),
            Token::Renamed => write!(f, "renamed"),
            Token::Share => write!(f, "share"),
            Token::Type => write!(f, "type"),
            Token::Const => write!(f, "const"),
            Token::TypeString => write!(f, "String"),
            Token::TypeInt => write!(f, "Int"),
            Token::TypeFloat => write!(f, "Float"),
            Token::TypeBool => write!(f, "Bool"),
            Token::Maybe => write!(f, "Maybe"),
            Token::Must => write!(f, "must"),
            Token::Have => write!(f, "have"),
            Token::Care => write!(f, "care"),
            Token::Strict => write!(f, "strict"),
            Token::Verbose => write!(f, "verbose"),
            Token::True => write!(f, "true"),
            Token::False => write!(f, "false"),
            Token::And => write!(f, "and"),
            Token::Or => write!(f, "or"),
            Token::Not => write!(f, "not"),
            Token::Plus => write!(f, "+"),
            Token::Minus => write!(f, "-"),
            Token::Star => write!(f, "*"),
            Token::Slash => write!(f, "/"),
            Token::Percent => write!(f, "%"),
            Token::EqualEqual => write!(f, "=="),
            Token::BangEqual => write!(f, "!="),
            Token::Less => write!(f, "<"),
            Token::Greater => write!(f, ">"),
            Token::LessEqual => write!(f, "<="),
            Token::GreaterEqual => write!(f, ">="),
            Token::Equal => write!(f, "="),
            Token::Arrow => write!(f, "→"),
            Token::AsciiArrow => write!(f, "->"),
            Token::LParen => write!(f, "("),
            Token::RParen => write!(f, ")"),
            Token::LBrace => write!(f, "{{"),
            Token::RBrace => write!(f, "}}"),
            Token::LBracket => write!(f, "["),
            Token::RBracket => write!(f, "]"),
            Token::Comma => write!(f, ","),
            Token::Semicolon => write!(f, ";"),
            Token::Colon => write!(f, ":"),
            Token::Dot => write!(f, "."),
            Token::At => write!(f, "@"),
            Token::Ampersand => write!(f, "&"),
            Token::Pipe => write!(f, "|"),
            Token::Hash => write!(f, "#"),
            Token::Underscore => write!(f, "_"),
            Token::Question => write!(f, "?"),
            Token::OkayType => write!(f, "Okay"),
            Token::Oops => write!(f, "Oops"),
            Token::Unwrap => write!(f, "unwrap"),
            Token::Integer(n) => write!(f, "{}", n),
            Token::Float(n) => write!(f, "{}", n),
            Token::String(s) => write!(f, "\"{}\"", s),
            Token::Identifier(s) => write!(f, "{}", s),
            Token::Eof => write!(f, "EOF"),
        }
    }
}
