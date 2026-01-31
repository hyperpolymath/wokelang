// SPDX-License-Identifier: PMPL-1.0-or-later
//! aggregate-library (aLib) Implementation for WokeLang
//!
//! This module implements the 22 core operations from aggregate-library,
//! providing a minimal overlap library with spec-driven, conformance-tested
//! implementations.
//!
//! Reference: https://github.com/hyperpolymath/aggregate-library

use super::{check_arity, StdlibError};
use crate::interpreter::Value;
use crate::security::CapabilityRegistry;

// ============================================================================
// ARITHMETIC (5 operations)
// ============================================================================

/// add: Number, Number -> Number
/// Computes the sum of two numbers.
///
/// Properties:
/// - Commutative: add(a, b) = add(b, a)
/// - Associative: add(add(a, b), c) = add(a, add(b, c))
/// - Identity element: add(a, 0) = a
pub fn add(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Int(a), Value::Int(b)) => Ok(Value::Int(a + b)),
        (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a + b)),
        (Value::Int(a), Value::Float(b)) => Ok(Value::Float(*a as f64 + b)),
        (Value::Float(a), Value::Int(b)) => Ok(Value::Float(a + *b as f64)),
        _ => Err(StdlibError::TypeError {
            expected: "Number".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

/// subtract: Number, Number -> Number
/// Computes the difference of two numbers (a - b).
pub fn subtract(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Int(a), Value::Int(b)) => Ok(Value::Int(a - b)),
        (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a - b)),
        (Value::Int(a), Value::Float(b)) => Ok(Value::Float(*a as f64 - b)),
        (Value::Float(a), Value::Int(b)) => Ok(Value::Float(a - *b as f64)),
        _ => Err(StdlibError::TypeError {
            expected: "Number".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

/// multiply: Number, Number -> Number
/// Computes the product of two numbers.
pub fn multiply(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Int(a), Value::Int(b)) => Ok(Value::Int(a * b)),
        (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a * b)),
        (Value::Int(a), Value::Float(b)) => Ok(Value::Float(*a as f64 * b)),
        (Value::Float(a), Value::Int(b)) => Ok(Value::Float(a * (*b as f64))),
        _ => Err(StdlibError::TypeError {
            expected: "Number".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

/// divide: Number, Number -> Number
/// Computes the quotient of two numbers (a / b).
pub fn divide(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Int(a), Value::Int(b)) => {
            if *b == 0 {
                Err(StdlibError::RuntimeError("Division by zero".to_string()))
            } else {
                Ok(Value::Int(a / b))
            }
        }
        (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a / b)),
        (Value::Int(a), Value::Float(b)) => Ok(Value::Float(*a as f64 / b)),
        (Value::Float(a), Value::Int(b)) => Ok(Value::Float(a / *b as f64)),
        _ => Err(StdlibError::TypeError {
            expected: "Number".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

/// modulo: Number, Number -> Number
/// Computes the remainder of dividing a by b.
pub fn modulo(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Int(a), Value::Int(b)) => {
            if *b == 0 {
                Err(StdlibError::RuntimeError("Modulo by zero".to_string()))
            } else {
                Ok(Value::Int(a % b))
            }
        }
        (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a % b)),
        (Value::Int(a), Value::Float(b)) => Ok(Value::Float(*a as f64 % b)),
        (Value::Float(a), Value::Int(b)) => Ok(Value::Float(a % *b as f64)),
        _ => Err(StdlibError::TypeError {
            expected: "Number".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

// ============================================================================
// COMPARISON (6 operations)
// ============================================================================

/// equal: A, A -> Boolean
/// Tests if two values are equal.
pub fn equal(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    Ok(Value::Bool(args[0] == args[1]))
}

/// notEqual: A, A -> Boolean
/// Tests if two values are not equal.
pub fn not_equal(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    Ok(Value::Bool(args[0] != args[1]))
}

/// lessThan: Number, Number -> Boolean
/// Tests if a is strictly less than b.
pub fn less_than(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a < b)),
        (Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a < b)),
        (Value::Int(a), Value::Float(b)) => Ok(Value::Bool((*a as f64) < *b)),
        (Value::Float(a), Value::Int(b)) => Ok(Value::Bool(*a < (*b as f64))),
        _ => Err(StdlibError::TypeError {
            expected: "Number".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

/// lessEqual: Number, Number -> Boolean
/// Tests if a is less than or equal to b.
pub fn less_equal(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a <= b)),
        (Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a <= b)),
        (Value::Int(a), Value::Float(b)) => Ok(Value::Bool((*a as f64) <= *b)),
        (Value::Float(a), Value::Int(b)) => Ok(Value::Bool(*a <= (*b as f64))),
        _ => Err(StdlibError::TypeError {
            expected: "Number".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

/// greaterThan: Number, Number -> Boolean
/// Tests if a is strictly greater than b.
pub fn greater_than(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a > b)),
        (Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a > b)),
        (Value::Int(a), Value::Float(b)) => Ok(Value::Bool((*a as f64) > *b)),
        (Value::Float(a), Value::Int(b)) => Ok(Value::Bool(*a > (*b as f64))),
        _ => Err(StdlibError::TypeError {
            expected: "Number".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

/// greaterEqual: Number, Number -> Boolean
/// Tests if a is greater than or equal to b.
pub fn greater_equal(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a >= b)),
        (Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a >= b)),
        (Value::Int(a), Value::Float(b)) => Ok(Value::Bool((*a as f64) >= *b)),
        (Value::Float(a), Value::Int(b)) => Ok(Value::Bool(*a >= (*b as f64))),
        _ => Err(StdlibError::TypeError {
            expected: "Number".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

// ============================================================================
// LOGICAL (3 operations)
// ============================================================================

/// and: Boolean, Boolean -> Boolean
/// Logical conjunction (AND operation).
pub fn and(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Bool(a), Value::Bool(b)) => Ok(Value::Bool(*a && *b)),
        _ => Err(StdlibError::TypeError {
            expected: "Boolean".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

/// or: Boolean, Boolean -> Boolean
/// Logical disjunction (OR operation).
pub fn or(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Bool(a), Value::Bool(b)) => Ok(Value::Bool(*a || *b)),
        _ => Err(StdlibError::TypeError {
            expected: "Boolean".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

/// not: Boolean -> Boolean
/// Logical negation (NOT operation).
pub fn not(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;

    match &args[0] {
        Value::Bool(a) => Ok(Value::Bool(!a)),
        _ => Err(StdlibError::TypeError {
            expected: "Boolean".to_string(),
            got: format!("{:?}", args[0]),
        }),
    }
}

// ============================================================================
// COLLECTION (4 operations)
// ============================================================================

/// map: Collection[A], Function[A -> B] -> Collection[B]
/// Transforms each element of a collection by applying a function.
pub fn map(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Array(arr), Value::Function(closure)) => {
            // Note: Actual mapping would require interpreter context
            // This is a placeholder showing the signature
            Err(StdlibError::RuntimeError(
                "map requires interpreter context (not yet implemented in stdlib)".to_string(),
            ))
        }
        _ => Err(StdlibError::TypeError {
            expected: "Array, Function".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

/// filter: Collection[A], Function[A -> Boolean] -> Collection[A]
/// Selects elements from a collection that satisfy a predicate.
pub fn filter(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::Array(_arr), Value::Function(_closure)) => Err(StdlibError::RuntimeError(
            "filter requires interpreter context (not yet implemented in stdlib)".to_string(),
        )),
        _ => Err(StdlibError::TypeError {
            expected: "Array, Function".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

/// fold: Collection[A], B, Function[B, A -> B] -> B
/// Reduces a collection to a single value by iteratively applying a function.
pub fn fold(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 3)?;

    match (&args[0], &args[2]) {
        (Value::Array(_arr), Value::Function(_closure)) => Err(StdlibError::RuntimeError(
            "fold requires interpreter context (not yet implemented in stdlib)".to_string(),
        )),
        _ => Err(StdlibError::TypeError {
            expected: "Array, Initial, Function".to_string(),
            got: format!("{:?}, {:?}, {:?}", args[0], args[1], args[2]),
        }),
    }
}

/// contains: Collection[A], A -> Boolean
/// Tests if a collection contains a specific element.
pub fn contains(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match &args[0] {
        Value::Array(arr) => Ok(Value::Bool(arr.contains(&args[1]))),
        _ => Err(StdlibError::TypeError {
            expected: "Array".to_string(),
            got: format!("{:?}", args[0]),
        }),
    }
}

// ============================================================================
// STRING (3 operations)
// ============================================================================

/// concat: String, String -> String
/// Concatenates two strings.
pub fn concat(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    match (&args[0], &args[1]) {
        (Value::String(a), Value::String(b)) => Ok(Value::String(format!("{}{}", a, b))),
        _ => Err(StdlibError::TypeError {
            expected: "String, String".to_string(),
            got: format!("{:?}, {:?}", args[0], args[1]),
        }),
    }
}

/// length: String -> Number
/// Returns the number of characters in a string.
pub fn str_length(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;

    match &args[0] {
        Value::String(s) => Ok(Value::Int(s.len() as i64)),
        _ => Err(StdlibError::TypeError {
            expected: "String".to_string(),
            got: format!("{:?}", args[0]),
        }),
    }
}

/// substring: String, Number, Number -> String
/// Extracts a substring from index 'start' to index 'end' (exclusive).
pub fn substring(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 3)?;

    match (&args[0], &args[1], &args[2]) {
        (Value::String(s), Value::Int(start), Value::Int(end)) => {
            let start = *start as usize;
            let end = *end as usize;

            if start >= s.len() || start >= end {
                return Ok(Value::String("".to_string()));
            }

            let end = std::cmp::min(end, s.len());
            Ok(Value::String(s[start..end].to_string()))
        }
        _ => Err(StdlibError::TypeError {
            expected: "String, Number, Number".to_string(),
            got: format!("{:?}, {:?}, {:?}", args[0], args[1], args[2]),
        }),
    }
}

// ============================================================================
// CONDITIONAL (1 operation)
// ============================================================================

/// ifThenElse: Boolean, () -> A, () -> A -> A
/// Evaluates one of two thunks based on a condition.
///
/// Note: In WokeLang, this is better handled by the built-in `when/otherwise` syntax.
/// This function is provided for aLib compliance but using native conditionals is preferred.
pub fn if_then_else(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 3)?;

    match (&args[0], &args[1], &args[2]) {
        (Value::Bool(_cond), Value::Function(_then_fn), Value::Function(_else_fn)) => {
            Err(StdlibError::RuntimeError(
                "ifThenElse requires interpreter context for thunk evaluation".to_string(),
            ))
        }
        _ => Err(StdlibError::TypeError {
            expected: "Boolean, Function, Function".to_string(),
            got: format!("{:?}, {:?}, {:?}", args[0], args[1], args[2]),
        }),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_caps() -> CapabilityRegistry {
        CapabilityRegistry::permissive()
    }

    // Arithmetic tests
    #[test]
    fn test_add() {
        let mut caps = test_caps();
        let result = add(&[Value::Int(2), Value::Int(3)], &mut caps).unwrap();
        assert_eq!(result, Value::Int(5));
    }

    #[test]
    fn test_subtract() {
        let mut caps = test_caps();
        let result = subtract(&[Value::Int(10), Value::Int(3)], &mut caps).unwrap();
        assert_eq!(result, Value::Int(7));
    }

    #[test]
    fn test_multiply() {
        let mut caps = test_caps();
        let result = multiply(&[Value::Int(4), Value::Int(5)], &mut caps).unwrap();
        assert_eq!(result, Value::Int(20));
    }

    #[test]
    fn test_divide() {
        let mut caps = test_caps();
        let result = divide(&[Value::Int(20), Value::Int(4)], &mut caps).unwrap();
        assert_eq!(result, Value::Int(5));
    }

    #[test]
    fn test_modulo() {
        let mut caps = test_caps();
        let result = modulo(&[Value::Int(10), Value::Int(3)], &mut caps).unwrap();
        assert_eq!(result, Value::Int(1));
    }

    // Comparison tests
    #[test]
    fn test_equal() {
        let mut caps = test_caps();
        assert_eq!(
            equal(&[Value::Int(5), Value::Int(5)], &mut caps).unwrap(),
            Value::Bool(true)
        );
        assert_eq!(
            equal(&[Value::Int(5), Value::Int(3)], &mut caps).unwrap(),
            Value::Bool(false)
        );
    }

    #[test]
    fn test_less_than() {
        let mut caps = test_caps();
        assert_eq!(
            less_than(&[Value::Int(3), Value::Int(5)], &mut caps).unwrap(),
            Value::Bool(true)
        );
        assert_eq!(
            less_than(&[Value::Int(5), Value::Int(3)], &mut caps).unwrap(),
            Value::Bool(false)
        );
    }

    // Logical tests
    #[test]
    fn test_and() {
        let mut caps = test_caps();
        assert_eq!(
            and(&[Value::Bool(true), Value::Bool(true)], &mut caps).unwrap(),
            Value::Bool(true)
        );
        assert_eq!(
            and(&[Value::Bool(true), Value::Bool(false)], &mut caps).unwrap(),
            Value::Bool(false)
        );
    }

    #[test]
    fn test_or() {
        let mut caps = test_caps();
        assert_eq!(
            or(&[Value::Bool(false), Value::Bool(true)], &mut caps).unwrap(),
            Value::Bool(true)
        );
        assert_eq!(
            or(&[Value::Bool(false), Value::Bool(false)], &mut caps).unwrap(),
            Value::Bool(false)
        );
    }

    #[test]
    fn test_not() {
        let mut caps = test_caps();
        assert_eq!(
            not(&[Value::Bool(true)], &mut caps).unwrap(),
            Value::Bool(false)
        );
        assert_eq!(
            not(&[Value::Bool(false)], &mut caps).unwrap(),
            Value::Bool(true)
        );
    }

    // Collection tests
    #[test]
    fn test_contains() {
        let mut caps = test_caps();
        let arr = vec![Value::Int(1), Value::Int(2), Value::Int(3)];
        assert_eq!(
            contains(&[Value::Array(arr.clone()), Value::Int(2)], &mut caps).unwrap(),
            Value::Bool(true)
        );
        assert_eq!(
            contains(&[Value::Array(arr), Value::Int(5)], &mut caps).unwrap(),
            Value::Bool(false)
        );
    }

    // String tests
    #[test]
    fn test_concat() {
        let mut caps = test_caps();
        let result = concat(
            &[
                Value::String("hello".to_string()),
                Value::String(" world".to_string()),
            ],
            &mut caps,
        )
        .unwrap();
        assert_eq!(result, Value::String("hello world".to_string()));
    }

    #[test]
    fn test_str_length() {
        let mut caps = test_caps();
        let result = str_length(&[Value::String("hello".to_string())], &mut caps).unwrap();
        assert_eq!(result, Value::Int(5));
    }

    #[test]
    fn test_substring() {
        let mut caps = test_caps();
        let result = substring(
            &[
                Value::String("hello world".to_string()),
                Value::Int(0),
                Value::Int(5),
            ],
            &mut caps,
        )
        .unwrap();
        assert_eq!(result, Value::String("hello".to_string()));
    }
}
