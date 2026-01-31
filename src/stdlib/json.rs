// SPDX-License-Identifier: PMPL-1.0-or-later
//! JSON parsing and serialization for WokeLang
//!
//! Provides consent-aware JSON operations.

use crate::interpreter::Value;
use crate::security::{Capability, CapabilityRegistry};
use crate::stdlib::{check_arity, StdlibError};
use std::collections::HashMap;

/// Parse a JSON string into a WokeLang value
///
/// Requires: std.json.parse capability
pub fn parse(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;

    // Check capability
    let cap = Capability::Custom("std.json.parse".to_string());
    caps.request("stdlib", &cap)
        .map_err(|_| StdlibError::PermissionDenied("std.json.parse".to_string()))?;

    let json_str = match &args[0] {
        Value::String(s) => s,
        v => {
            return Err(StdlibError::TypeError {
                expected: "String".to_string(),
                got: format!("{:?}", v),
            })
        }
    };

    parse_json_string(json_str)
}

/// Stringify a WokeLang value to JSON
///
/// Requires: std.json.stringify capability
pub fn stringify(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;

    // Check capability
    let cap = Capability::Custom("std.json.stringify".to_string());
    caps.request("stdlib", &cap)
        .map_err(|_| StdlibError::PermissionDenied("std.json.stringify".to_string()))?;

    let json_string = value_to_json_string(&args[0])?;
    Ok(Value::String(json_string))
}

/// Parse JSON string to WokeLang Value
fn parse_json_string(s: &str) -> Result<Value, StdlibError> {
    let trimmed = s.trim();

    // Null
    if trimmed == "null" {
        return Ok(Value::Unit);
    }

    // Boolean
    if trimmed == "true" {
        return Ok(Value::Bool(true));
    }
    if trimmed == "false" {
        return Ok(Value::Bool(false));
    }

    // Number
    if let Ok(i) = trimmed.parse::<i64>() {
        return Ok(Value::Int(i));
    }
    if let Ok(f) = trimmed.parse::<f64>() {
        return Ok(Value::Float(f));
    }

    // String
    if trimmed.starts_with('"') && trimmed.ends_with('"') {
        let content = &trimmed[1..trimmed.len() - 1];
        let unescaped = unescape_json_string(content)?;
        return Ok(Value::String(unescaped));
    }

    // Array
    if trimmed.starts_with('[') && trimmed.ends_with(']') {
        let content = &trimmed[1..trimmed.len() - 1];
        if content.trim().is_empty() {
            return Ok(Value::Array(Vec::new()));
        }

        let elements = split_json_array(content)?;
        let values: Result<Vec<_>, _> = elements
            .iter()
            .map(|e| parse_json_string(e))
            .collect();
        return Ok(Value::Array(values?));
    }

    // Object (map to Record)
    if trimmed.starts_with('{') && trimmed.ends_with('}') {
        let content = &trimmed[1..trimmed.len() - 1];
        if content.trim().is_empty() {
            return Ok(Value::Record(HashMap::new()));
        }

        let pairs = split_json_object(content)?;
        let mut map = HashMap::new();

        for pair in pairs {
            let (key, value) = parse_json_pair(&pair)?;
            map.insert(key, value);
        }

        return Ok(Value::Record(map));
    }

    Err(StdlibError::ParseError(format!(
        "Invalid JSON: {}",
        trimmed
    )))
}

/// Convert WokeLang Value to JSON string
fn value_to_json_string(value: &Value) -> Result<String, StdlibError> {
    match value {
        Value::Unit => Ok("null".to_string()),
        Value::Bool(b) => Ok(b.to_string()),
        Value::Int(i) => Ok(i.to_string()),
        Value::Float(f) => Ok(f.to_string()),
        Value::String(s) => Ok(format!("\"{}\"", escape_json_string(s))),
        Value::Array(arr) => {
            let elements: Result<Vec<_>, _> =
                arr.iter().map(value_to_json_string).collect();
            Ok(format!("[{}]", elements?.join(",")))
        }
        Value::Record(map) => {
            let pairs: Result<Vec<_>, _> = map
                .iter()
                .map(|(k, v)| {
                    let val_str = value_to_json_string(v)?;
                    Ok(format!("\"{}\":{}", escape_json_string(k), val_str))
                })
                .collect();
            Ok(format!("{{{}}}", pairs?.join(",")))
        }
        Value::Function(_) => Err(StdlibError::RuntimeError(
            "Cannot stringify function to JSON".to_string(),
        )),
        Value::Channel(_) => Err(StdlibError::RuntimeError(
            "Cannot stringify channel to JSON".to_string(),
        )),
        Value::Okay(_) | Value::Oops(_) => Err(StdlibError::RuntimeError(
            "Cannot stringify Result to JSON".to_string(),
        )),
    }
}

/// Unescape JSON string (handle \\n, \\t, \\", etc.)
fn unescape_json_string(s: &str) -> Result<String, StdlibError> {
    let mut result = String::new();
    let mut chars = s.chars();

    while let Some(ch) = chars.next() {
        if ch == '\\' {
            match chars.next() {
                Some('n') => result.push('\n'),
                Some('t') => result.push('\t'),
                Some('r') => result.push('\r'),
                Some('"') => result.push('"'),
                Some('\\') => result.push('\\'),
                Some('/') => result.push('/'),
                Some('b') => result.push('\u{0008}'),
                Some('f') => result.push('\u{000C}'),
                Some(c) => {
                    return Err(StdlibError::ParseError(format!(
                        "Invalid escape sequence: \\{}",
                        c
                    )))
                }
                None => {
                    return Err(StdlibError::ParseError(
                        "Unterminated escape sequence".to_string(),
                    ))
                }
            }
        } else {
            result.push(ch);
        }
    }

    Ok(result)
}

/// Escape string for JSON
fn escape_json_string(s: &str) -> String {
    s.chars()
        .map(|ch| match ch {
            '\n' => "\\n".to_string(),
            '\t' => "\\t".to_string(),
            '\r' => "\\r".to_string(),
            '"' => "\\\"".to_string(),
            '\\' => "\\\\".to_string(),
            c => c.to_string(),
        })
        .collect()
}

/// Split JSON array by commas (respecting nesting)
fn split_json_array(s: &str) -> Result<Vec<String>, StdlibError> {
    let mut result = Vec::new();
    let mut current = String::new();
    let mut depth = 0;
    let mut in_string = false;
    let mut escape_next = false;

    for ch in s.chars() {
        if escape_next {
            current.push(ch);
            escape_next = false;
            continue;
        }

        match ch {
            '\\' if in_string => {
                escape_next = true;
                current.push(ch);
            }
            '"' => {
                in_string = !in_string;
                current.push(ch);
            }
            '[' | '{' if !in_string => {
                depth += 1;
                current.push(ch);
            }
            ']' | '}' if !in_string => {
                depth -= 1;
                current.push(ch);
            }
            ',' if depth == 0 && !in_string => {
                result.push(current.trim().to_string());
                current.clear();
            }
            _ => current.push(ch),
        }
    }

    if !current.trim().is_empty() {
        result.push(current.trim().to_string());
    }

    Ok(result)
}

/// Split JSON object by commas (respecting nesting)
fn split_json_object(s: &str) -> Result<Vec<String>, StdlibError> {
    split_json_array(s) // Same logic
}

/// Parse JSON key:value pair
fn parse_json_pair(s: &str) -> Result<(String, Value), StdlibError> {
    let colon_pos = find_json_colon(s)?;
    let key_str = s[..colon_pos].trim();
    let value_str = s[colon_pos + 1..].trim();

    // Parse key (must be string)
    if !key_str.starts_with('"') || !key_str.ends_with('"') {
        return Err(StdlibError::ParseError(format!(
            "Object key must be string: {}",
            key_str
        )));
    }

    let key = unescape_json_string(&key_str[1..key_str.len() - 1])?;
    let value = parse_json_string(value_str)?;

    Ok((key, value))
}

/// Find the colon that separates key and value in JSON object
fn find_json_colon(s: &str) -> Result<usize, StdlibError> {
    let mut in_string = false;
    let mut escape_next = false;

    for (i, ch) in s.chars().enumerate() {
        if escape_next {
            escape_next = false;
            continue;
        }

        match ch {
            '\\' if in_string => escape_next = true,
            '"' => in_string = !in_string,
            ':' if !in_string => return Ok(i),
            _ => {}
        }
    }

    Err(StdlibError::ParseError(
        "No colon found in object pair".to_string(),
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_caps() -> CapabilityRegistry {
        let mut caps = CapabilityRegistry::permissive();
        caps
    }

    #[test]
    fn test_parse_null() {
        let args = vec![Value::String("null".to_string())];
        let mut caps = test_caps();
        let result = parse(&args, &mut caps).unwrap();
        assert!(matches!(result, Value::Unit));
    }

    #[test]
    fn test_parse_bool() {
        let mut caps = test_caps();

        let args = vec![Value::String("true".to_string())];
        let result = parse(&args, &mut caps).unwrap();
        assert_eq!(result, Value::Bool(true));

        let args = vec![Value::String("false".to_string())];
        let result = parse(&args, &mut caps).unwrap();
        assert_eq!(result, Value::Bool(false));
    }

    #[test]
    fn test_parse_number() {
        let mut caps = test_caps();

        let args = vec![Value::String("42".to_string())];
        let result = parse(&args, &mut caps).unwrap();
        assert_eq!(result, Value::Int(42));

        let args = vec![Value::String("3.14".to_string())];
        let result = parse(&args, &mut caps).unwrap();
        assert_eq!(result, Value::Float(3.14));
    }

    #[test]
    fn test_parse_string() {
        let mut caps = test_caps();
        let args = vec![Value::String("\"hello world\"".to_string())];
        let result = parse(&args, &mut caps).unwrap();
        assert_eq!(result, Value::String("hello world".to_string()));
    }

    #[test]
    fn test_parse_array() {
        let mut caps = test_caps();
        let args = vec![Value::String("[1, 2, 3]".to_string())];
        let result = parse(&args, &mut caps).unwrap();
        match result {
            Value::Array(arr) => {
                assert_eq!(arr.len(), 3);
                assert_eq!(arr[0], Value::Int(1));
                assert_eq!(arr[1], Value::Int(2));
                assert_eq!(arr[2], Value::Int(3));
            }
            _ => panic!("Expected array"),
        }
    }

    #[test]
    fn test_parse_object() {
        let mut caps = test_caps();
        let args = vec![Value::String("{\"name\": \"Alice\", \"age\": 30}".to_string())];
        let result = parse(&args, &mut caps).unwrap();
        match result {
            Value::Record(map) => {
                assert_eq!(map.len(), 2);
                assert_eq!(map.get("name"), Some(&Value::String("Alice".to_string())));
                assert_eq!(map.get("age"), Some(&Value::Int(30)));
            }
            _ => panic!("Expected record"),
        }
    }

    #[test]
    fn test_stringify() {
        let mut caps = test_caps();

        let args = vec![Value::Int(42)];
        let result = stringify(&args, &mut caps).unwrap();
        assert_eq!(result, Value::String("42".to_string()));

        let args = vec![Value::String("hello".to_string())];
        let result = stringify(&args, &mut caps).unwrap();
        assert_eq!(result, Value::String("\"hello\"".to_string()));

        let args = vec![Value::Array(vec![Value::Int(1), Value::Int(2)])];
        let result = stringify(&args, &mut caps).unwrap();
        assert_eq!(result, Value::String("[1,2]".to_string()));
    }

    #[test]
    fn test_permission_denied() {
        let args = vec![Value::String("null".to_string())];
        let mut caps = CapabilityRegistry::new(); // No permission granted
        let result = parse(&args, &mut caps);
        assert!(matches!(result, Err(StdlibError::PermissionDenied(_))));
    }
}
