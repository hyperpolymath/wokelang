//! WokeLang Standard Library - JSON Module
//!
//! JSON parsing and generation functions.

use crate::interpreter::Value;
use crate::security::CapabilityRegistry;
use super::{check_arity, expect_string, StdlibError};
use std::collections::HashMap;

/// Maximum JSON input size (1 MB)
const MAX_JSON_SIZE: usize = 1024 * 1024;

/// Maximum nesting depth for JSON parsing
const MAX_NESTING_DEPTH: usize = 100;

/// Simple JSON tokenizer
#[derive(Debug, Clone, PartialEq)]
enum JsonToken {
    LBrace,
    RBrace,
    LBracket,
    RBracket,
    Colon,
    Comma,
    String(String),
    Number(f64),
    True,
    False,
    Null,
}

/// Tokenize JSON string
fn tokenize(input: &str) -> Result<Vec<JsonToken>, StdlibError> {
    let mut tokens = Vec::new();
    let mut chars = input.chars().peekable();

    while let Some(&c) = chars.peek() {
        match c {
            ' ' | '\t' | '\n' | '\r' => {
                chars.next();
            }
            '{' => {
                chars.next();
                tokens.push(JsonToken::LBrace);
            }
            '}' => {
                chars.next();
                tokens.push(JsonToken::RBrace);
            }
            '[' => {
                chars.next();
                tokens.push(JsonToken::LBracket);
            }
            ']' => {
                chars.next();
                tokens.push(JsonToken::RBracket);
            }
            ':' => {
                chars.next();
                tokens.push(JsonToken::Colon);
            }
            ',' => {
                chars.next();
                tokens.push(JsonToken::Comma);
            }
            '"' => {
                chars.next();
                let mut s = String::new();
                while let Some(&c) = chars.peek() {
                    if c == '"' {
                        chars.next();
                        break;
                    } else if c == '\\' {
                        chars.next();
                        match chars.next() {
                            Some('n') => s.push('\n'),
                            Some('t') => s.push('\t'),
                            Some('r') => s.push('\r'),
                            Some('"') => s.push('"'),
                            Some('\\') => s.push('\\'),
                            Some('/') => s.push('/'),
                            Some(c) => s.push(c),
                            None => {
                                return Err(StdlibError::ParseError(
                                    "Unterminated escape sequence".to_string(),
                                ))
                            }
                        }
                    } else {
                        s.push(c);
                        chars.next();
                    }
                }
                tokens.push(JsonToken::String(s));
            }
            '-' | '0'..='9' => {
                let mut num_str = String::new();
                while let Some(&c) = chars.peek() {
                    if c == '-' || c == '+' || c == '.' || c == 'e' || c == 'E' || c.is_ascii_digit()
                    {
                        num_str.push(c);
                        chars.next();
                    } else {
                        break;
                    }
                }
                let num: f64 = num_str.parse().map_err(|_| {
                    StdlibError::ParseError(format!("Invalid number: {}", num_str))
                })?;
                tokens.push(JsonToken::Number(num));
            }
            't' => {
                for expected in ['t', 'r', 'u', 'e'] {
                    if chars.next() != Some(expected) {
                        return Err(StdlibError::ParseError("Expected 'true'".to_string()));
                    }
                }
                tokens.push(JsonToken::True);
            }
            'f' => {
                for expected in ['f', 'a', 'l', 's', 'e'] {
                    if chars.next() != Some(expected) {
                        return Err(StdlibError::ParseError("Expected 'false'".to_string()));
                    }
                }
                tokens.push(JsonToken::False);
            }
            'n' => {
                for expected in ['n', 'u', 'l', 'l'] {
                    if chars.next() != Some(expected) {
                        return Err(StdlibError::ParseError("Expected 'null'".to_string()));
                    }
                }
                tokens.push(JsonToken::Null);
            }
            _ => {
                return Err(StdlibError::ParseError(format!(
                    "Unexpected character: {}",
                    c
                )))
            }
        }
    }

    Ok(tokens)
}

/// Parse JSON tokens into Value with depth tracking
fn parse_value(tokens: &[JsonToken], pos: &mut usize, depth: usize) -> Result<Value, StdlibError> {
    if depth > MAX_NESTING_DEPTH {
        return Err(StdlibError::ParseError(format!(
            "JSON nesting too deep (max {} levels)",
            MAX_NESTING_DEPTH
        )));
    }

    if *pos >= tokens.len() {
        return Err(StdlibError::ParseError("Unexpected end of input".to_string()));
    }

    match &tokens[*pos] {
        JsonToken::LBrace => parse_object(tokens, pos, depth + 1),
        JsonToken::LBracket => parse_array(tokens, pos, depth + 1),
        JsonToken::String(s) => {
            *pos += 1;
            Ok(Value::String(s.clone()))
        }
        JsonToken::Number(n) => {
            *pos += 1;
            if n.fract() == 0.0 && *n >= i64::MIN as f64 && *n <= i64::MAX as f64 {
                Ok(Value::Int(*n as i64))
            } else {
                Ok(Value::Float(*n))
            }
        }
        JsonToken::True => {
            *pos += 1;
            Ok(Value::Bool(true))
        }
        JsonToken::False => {
            *pos += 1;
            Ok(Value::Bool(false))
        }
        JsonToken::Null => {
            *pos += 1;
            Ok(Value::Unit)
        }
        _ => Err(StdlibError::ParseError(format!(
            "Unexpected token: {:?}",
            tokens[*pos]
        ))),
    }
}

/// Parse JSON object
fn parse_object(tokens: &[JsonToken], pos: &mut usize, depth: usize) -> Result<Value, StdlibError> {
    *pos += 1; // consume '{'

    let mut map = HashMap::new();

    if *pos < tokens.len() && tokens[*pos] == JsonToken::RBrace {
        *pos += 1;
        return Ok(Value::Record(map));
    }

    loop {
        // Expect string key
        let key = match &tokens[*pos] {
            JsonToken::String(s) => {
                *pos += 1;
                s.clone()
            }
            _ => return Err(StdlibError::ParseError("Expected string key".to_string())),
        };

        // Expect colon
        if *pos >= tokens.len() || tokens[*pos] != JsonToken::Colon {
            return Err(StdlibError::ParseError("Expected ':'".to_string()));
        }
        *pos += 1;

        // Parse value
        let value = parse_value(tokens, pos, depth)?;
        map.insert(key, value);

        // Check for comma or end
        if *pos >= tokens.len() {
            return Err(StdlibError::ParseError("Unexpected end of object".to_string()));
        }

        match &tokens[*pos] {
            JsonToken::Comma => {
                *pos += 1;
            }
            JsonToken::RBrace => {
                *pos += 1;
                break;
            }
            _ => return Err(StdlibError::ParseError("Expected ',' or '}'".to_string())),
        }
    }

    Ok(Value::Record(map))
}

/// Parse JSON array
fn parse_array(tokens: &[JsonToken], pos: &mut usize, depth: usize) -> Result<Value, StdlibError> {
    *pos += 1; // consume '['

    let mut items = Vec::new();

    if *pos < tokens.len() && tokens[*pos] == JsonToken::RBracket {
        *pos += 1;
        return Ok(Value::Array(items));
    }

    loop {
        let value = parse_value(tokens, pos, depth)?;
        items.push(value);

        if *pos >= tokens.len() {
            return Err(StdlibError::ParseError("Unexpected end of array".to_string()));
        }

        match &tokens[*pos] {
            JsonToken::Comma => {
                *pos += 1;
            }
            JsonToken::RBracket => {
                *pos += 1;
                break;
            }
            _ => return Err(StdlibError::ParseError("Expected ',' or ']'".to_string())),
        }
    }

    Ok(Value::Array(items))
}

/// Convert Value to JSON string
fn stringify_value(value: &Value) -> String {
    match value {
        Value::Unit => "null".to_string(),
        Value::Bool(b) => b.to_string(),
        Value::Int(n) => n.to_string(),
        Value::Float(n) => {
            if n.is_finite() {
                n.to_string()
            } else {
                "null".to_string()
            }
        }
        Value::String(s) => {
            let escaped = s
                .replace('\\', "\\\\")
                .replace('"', "\\\"")
                .replace('\n', "\\n")
                .replace('\r', "\\r")
                .replace('\t', "\\t");
            format!("\"{}\"", escaped)
        }
        Value::Array(items) => {
            let items_str: Vec<String> = items.iter().map(stringify_value).collect();
            format!("[{}]", items_str.join(","))
        }
        Value::Record(map) => {
            let pairs: Vec<String> = map
                .iter()
                .map(|(k, v)| format!("\"{}\":{}", k, stringify_value(v)))
                .collect();
            format!("{{{}}}", pairs.join(","))
        }
        Value::Okay(inner) => stringify_value(inner),
        Value::Oops(msg) => format!("{{\"error\":\"{}\"}}", msg),
        Value::Function(_) => "null".to_string(), // Functions cannot be serialized to JSON
    }
}

/// Parse JSON string into WokeLang value
pub fn parse(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let json_str = expect_string(&args[0], "json")?;

    // Check input size to prevent memory exhaustion
    if json_str.len() > MAX_JSON_SIZE {
        return Err(StdlibError::ParseError(format!(
            "JSON input too large: {} bytes (max {} bytes)",
            json_str.len(),
            MAX_JSON_SIZE
        )));
    }

    let tokens = tokenize(&json_str)?;
    if tokens.is_empty() {
        return Err(StdlibError::ParseError("Empty JSON".to_string()));
    }

    let mut pos = 0;
    let value = parse_value(&tokens, &mut pos, 0)?;

    if pos < tokens.len() {
        return Err(StdlibError::ParseError("Trailing content after JSON".to_string()));
    }

    Ok(value)
}

/// Convert WokeLang value to JSON string
pub fn stringify(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    Ok(Value::String(stringify_value(&args[0])))
}

/// Get a value from a JSON object by key path
pub fn get(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let path = expect_string(&args[1], "path")?;

    let mut current = args[0].clone();

    for key in path.split('.') {
        match &current {
            Value::Record(map) => {
                current = map
                    .get(key)
                    .cloned()
                    .ok_or_else(|| StdlibError::RuntimeError(format!("Key not found: {}", key)))?;
            }
            Value::Array(items) => {
                let idx: usize = key.parse().map_err(|_| {
                    StdlibError::RuntimeError(format!("Invalid array index: {}", key))
                })?;
                current = items
                    .get(idx)
                    .cloned()
                    .ok_or_else(|| StdlibError::RuntimeError(format!("Index out of bounds: {}", idx)))?;
            }
            _ => {
                return Err(StdlibError::RuntimeError(format!(
                    "Cannot access key '{}' on non-object/array",
                    key
                )))
            }
        }
    }

    Ok(current)
}

/// Set a value in a JSON object by key
pub fn set(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 3)?;
    let key = expect_string(&args[1], "key")?;

    match &args[0] {
        Value::Record(map) => {
            let mut new_map = map.clone();
            new_map.insert(key, args[2].clone());
            Ok(Value::Record(new_map))
        }
        _ => Err(StdlibError::TypeError {
            expected: "Record".to_string(),
            got: format!("{:?}", args[0]),
        }),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_caps() -> CapabilityRegistry {
        CapabilityRegistry::permissive()
    }

    #[test]
    fn test_parse_primitives() {
        let mut caps = test_caps();

        assert_eq!(
            parse(&[Value::String("42".to_string())], &mut caps).unwrap(),
            Value::Int(42)
        );
        assert_eq!(
            parse(&[Value::String("3.14".to_string())], &mut caps).unwrap(),
            Value::Float(3.14)
        );
        assert_eq!(
            parse(&[Value::String("true".to_string())], &mut caps).unwrap(),
            Value::Bool(true)
        );
        assert_eq!(
            parse(&[Value::String("false".to_string())], &mut caps).unwrap(),
            Value::Bool(false)
        );
        assert_eq!(
            parse(&[Value::String("null".to_string())], &mut caps).unwrap(),
            Value::Unit
        );
        assert_eq!(
            parse(&[Value::String("\"hello\"".to_string())], &mut caps).unwrap(),
            Value::String("hello".to_string())
        );
    }

    #[test]
    fn test_parse_array() {
        let mut caps = test_caps();

        let result = parse(&[Value::String("[1, 2, 3]".to_string())], &mut caps).unwrap();
        assert_eq!(
            result,
            Value::Array(vec![
                Value::Int(1),
                Value::Int(2),
                Value::Int(3)
            ])
        );
    }

    #[test]
    fn test_parse_object() {
        let mut caps = test_caps();

        let result = parse(
            &[Value::String("{\"name\": \"WokeLang\", \"version\": 1}".to_string())],
            &mut caps,
        )
        .unwrap();

        match result {
            Value::Record(map) => {
                assert_eq!(map.get("name"), Some(&Value::String("WokeLang".to_string())));
                assert_eq!(map.get("version"), Some(&Value::Int(1)));
            }
            _ => panic!("Expected record"),
        }
    }

    #[test]
    fn test_stringify() {
        let mut caps = test_caps();

        assert_eq!(
            stringify(&[Value::Int(42)], &mut caps).unwrap(),
            Value::String("42".to_string())
        );
        assert_eq!(
            stringify(&[Value::String("hello".to_string())], &mut caps).unwrap(),
            Value::String("\"hello\"".to_string())
        );
        assert_eq!(
            stringify(&[Value::Bool(true)], &mut caps).unwrap(),
            Value::String("true".to_string())
        );
    }

    #[test]
    fn test_get() {
        let mut caps = test_caps();

        let json = parse(
            &[Value::String("{\"user\": {\"name\": \"Alice\"}}".to_string())],
            &mut caps,
        )
        .unwrap();

        let result = get(&[json, Value::String("user.name".to_string())], &mut caps).unwrap();
        assert_eq!(result, Value::String("Alice".to_string()));
    }

    #[test]
    fn test_set() {
        let mut caps = test_caps();

        let json = parse(&[Value::String("{\"x\": 1}".to_string())], &mut caps).unwrap();

        let result = set(
            &[json, Value::String("y".to_string()), Value::Int(2)],
            &mut caps,
        )
        .unwrap();

        match result {
            Value::Record(map) => {
                assert_eq!(map.get("x"), Some(&Value::Int(1)));
                assert_eq!(map.get("y"), Some(&Value::Int(2)));
            }
            _ => panic!("Expected record"),
        }
    }

    #[test]
    fn test_nesting_depth_limit() {
        let mut caps = test_caps();

        // Create deeply nested JSON (150 levels, should fail at 100)
        let deep_json = format!("{}1{}", "[".repeat(150), "]".repeat(150));

        let result = parse(&[Value::String(deep_json)], &mut caps);
        assert!(result.is_err());

        // Verify error message mentions nesting
        if let Err(StdlibError::ParseError(msg)) = result {
            assert!(msg.contains("nesting"));
        }
    }

    #[test]
    fn test_reasonable_nesting_ok() {
        let mut caps = test_caps();

        // Create moderately nested JSON (50 levels, should succeed)
        let nested_json = format!("{}1{}", "[".repeat(50), "]".repeat(50));

        let result = parse(&[Value::String(nested_json)], &mut caps);
        assert!(result.is_ok());
    }
}
