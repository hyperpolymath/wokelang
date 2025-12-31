//! WokeLang Standard Library - String Module
//!
//! String manipulation functions.

use crate::interpreter::Value;
use crate::security::CapabilityRegistry;
use super::{check_arity, check_arity_range, expect_int, expect_string, StdlibError};

/// Get the length of a string (in characters, not bytes)
pub fn length(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let s = expect_string(&args[0], "string")?;
    Ok(Value::Int(s.chars().count() as i64))
}

/// Convert string to uppercase
pub fn upper(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let s = expect_string(&args[0], "string")?;
    Ok(Value::String(s.to_uppercase()))
}

/// Convert string to lowercase
pub fn lower(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let s = expect_string(&args[0], "string")?;
    Ok(Value::String(s.to_lowercase()))
}

/// Trim whitespace from both ends
pub fn trim(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let s = expect_string(&args[0], "string")?;
    Ok(Value::String(s.trim().to_string()))
}

/// Trim whitespace from start
pub fn trim_start(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let s = expect_string(&args[0], "string")?;
    Ok(Value::String(s.trim_start().to_string()))
}

/// Trim whitespace from end
pub fn trim_end(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let s = expect_string(&args[0], "string")?;
    Ok(Value::String(s.trim_end().to_string()))
}

/// Check if string contains a substring
pub fn contains(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let s = expect_string(&args[0], "string")?;
    let substring = expect_string(&args[1], "substring")?;
    Ok(Value::Bool(s.contains(&substring)))
}

/// Check if string starts with a prefix
pub fn starts_with(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let s = expect_string(&args[0], "string")?;
    let prefix = expect_string(&args[1], "prefix")?;
    Ok(Value::Bool(s.starts_with(&prefix)))
}

/// Check if string ends with a suffix
pub fn ends_with(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let s = expect_string(&args[0], "string")?;
    let suffix = expect_string(&args[1], "suffix")?;
    Ok(Value::Bool(s.ends_with(&suffix)))
}

/// Replace all occurrences of a pattern
pub fn replace(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 3)?;
    let s = expect_string(&args[0], "string")?;
    let from = expect_string(&args[1], "from")?;
    let to = expect_string(&args[2], "to")?;
    Ok(Value::String(s.replace(&from, &to)))
}

/// Split string by delimiter
pub fn split(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let s = expect_string(&args[0], "string")?;
    let delimiter = expect_string(&args[1], "delimiter")?;
    let parts: Vec<Value> = s.split(&delimiter).map(|p| Value::String(p.to_string())).collect();
    Ok(Value::Array(parts))
}

/// Join array of strings with delimiter
pub fn join(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    let arr = match &args[0] {
        Value::Array(a) => a,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Array".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    let delimiter = expect_string(&args[1], "delimiter")?;

    let strings: Result<Vec<String>, _> = arr
        .iter()
        .map(|v| match v {
            Value::String(s) => Ok(s.clone()),
            other => Err(StdlibError::TypeError {
                expected: "String".to_string(),
                got: format!("{:?}", other),
            }),
        })
        .collect();

    Ok(Value::String(strings?.join(&delimiter)))
}

/// Get substring by start and optional end index
pub fn substring(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity_range(args, 2, 3)?;
    let s = expect_string(&args[0], "string")?;
    let start = expect_int(&args[1], "start")?;

    let chars: Vec<char> = s.chars().collect();
    let len = chars.len() as i64;

    // Handle negative indices
    let start_idx = if start < 0 {
        ((len + start).max(0)) as usize
    } else {
        start.min(len) as usize
    };

    let end_idx = if args.len() > 2 {
        let end = expect_int(&args[2], "end")?;
        if end < 0 {
            ((len + end).max(0)) as usize
        } else {
            end.min(len) as usize
        }
    } else {
        len as usize
    };

    if start_idx >= end_idx {
        return Ok(Value::String(String::new()));
    }

    Ok(Value::String(chars[start_idx..end_idx].iter().collect()))
}

/// Find index of first occurrence of substring
pub fn index_of(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let s = expect_string(&args[0], "string")?;
    let needle = expect_string(&args[1], "needle")?;

    match s.find(&needle) {
        Some(idx) => {
            // Convert byte index to character index
            let char_idx = s[..idx].chars().count();
            Ok(Value::Int(char_idx as i64))
        }
        None => Ok(Value::Int(-1)),
    }
}

/// Repeat string n times
pub fn repeat(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let s = expect_string(&args[0], "string")?;
    let n = expect_int(&args[1], "count")?;

    if n < 0 {
        return Err(StdlibError::RuntimeError("repeat count cannot be negative".to_string()));
    }

    if n > 10000 {
        return Err(StdlibError::RuntimeError("repeat count too large (max 10000)".to_string()));
    }

    Ok(Value::String(s.repeat(n as usize)))
}

/// Reverse a string
pub fn reverse(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let s = expect_string(&args[0], "string")?;
    Ok(Value::String(s.chars().rev().collect()))
}

/// Pad string on the left to reach target length
pub fn pad_start(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity_range(args, 2, 3)?;
    let s = expect_string(&args[0], "string")?;
    let target_len = expect_int(&args[1], "length")? as usize;
    let pad_char = if args.len() > 2 {
        let p = expect_string(&args[2], "pad")?;
        p.chars().next().unwrap_or(' ')
    } else {
        ' '
    };

    let current_len = s.chars().count();
    if current_len >= target_len {
        return Ok(Value::String(s));
    }

    let padding: String = std::iter::repeat(pad_char).take(target_len - current_len).collect();
    Ok(Value::String(format!("{}{}", padding, s)))
}

/// Pad string on the right to reach target length
pub fn pad_end(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity_range(args, 2, 3)?;
    let s = expect_string(&args[0], "string")?;
    let target_len = expect_int(&args[1], "length")? as usize;
    let pad_char = if args.len() > 2 {
        let p = expect_string(&args[2], "pad")?;
        p.chars().next().unwrap_or(' ')
    } else {
        ' '
    };

    let current_len = s.chars().count();
    if current_len >= target_len {
        return Ok(Value::String(s));
    }

    let padding: String = std::iter::repeat(pad_char).take(target_len - current_len).collect();
    Ok(Value::String(format!("{}{}", s, padding)))
}

/// Split string into array of characters
pub fn chars(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let s = expect_string(&args[0], "string")?;
    let char_array: Vec<Value> = s.chars().map(|c| Value::String(c.to_string())).collect();
    Ok(Value::Array(char_array))
}

/// Check if string is empty
pub fn is_empty(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let s = expect_string(&args[0], "string")?;
    Ok(Value::Bool(s.is_empty()))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_caps() -> CapabilityRegistry {
        CapabilityRegistry::permissive()
    }

    #[test]
    fn test_length() {
        let mut caps = test_caps();
        assert_eq!(
            length(&[Value::String("hello".to_string())], &mut caps).unwrap(),
            Value::Int(5)
        );
        // UTF-8 characters
        assert_eq!(
            length(&[Value::String("你好".to_string())], &mut caps).unwrap(),
            Value::Int(2)
        );
    }

    #[test]
    fn test_upper_lower() {
        let mut caps = test_caps();
        assert_eq!(
            upper(&[Value::String("hello".to_string())], &mut caps).unwrap(),
            Value::String("HELLO".to_string())
        );
        assert_eq!(
            lower(&[Value::String("HELLO".to_string())], &mut caps).unwrap(),
            Value::String("hello".to_string())
        );
    }

    #[test]
    fn test_trim() {
        let mut caps = test_caps();
        assert_eq!(
            trim(&[Value::String("  hello  ".to_string())], &mut caps).unwrap(),
            Value::String("hello".to_string())
        );
    }

    #[test]
    fn test_contains() {
        let mut caps = test_caps();
        assert_eq!(
            contains(
                &[Value::String("hello world".to_string()), Value::String("world".to_string())],
                &mut caps
            )
            .unwrap(),
            Value::Bool(true)
        );
    }

    #[test]
    fn test_split_join() {
        let mut caps = test_caps();
        let result = split(
            &[Value::String("a,b,c".to_string()), Value::String(",".to_string())],
            &mut caps,
        )
        .unwrap();

        assert_eq!(
            result,
            Value::Array(vec![
                Value::String("a".to_string()),
                Value::String("b".to_string()),
                Value::String("c".to_string()),
            ])
        );

        let joined = join(
            &[result, Value::String("-".to_string())],
            &mut caps,
        )
        .unwrap();

        assert_eq!(joined, Value::String("a-b-c".to_string()));
    }

    #[test]
    fn test_substring() {
        let mut caps = test_caps();
        assert_eq!(
            substring(
                &[Value::String("hello".to_string()), Value::Int(1), Value::Int(4)],
                &mut caps
            )
            .unwrap(),
            Value::String("ell".to_string())
        );
    }

    #[test]
    fn test_replace() {
        let mut caps = test_caps();
        assert_eq!(
            replace(
                &[
                    Value::String("hello world".to_string()),
                    Value::String("world".to_string()),
                    Value::String("rust".to_string())
                ],
                &mut caps
            )
            .unwrap(),
            Value::String("hello rust".to_string())
        );
    }
}
