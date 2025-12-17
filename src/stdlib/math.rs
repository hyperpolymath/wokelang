//! WokeLang Standard Library - Math Module
//!
//! Mathematical functions that don't require any special capabilities.

use crate::interpreter::Value;
use crate::security::CapabilityRegistry;
use super::{check_arity, check_arity_range, expect_float, StdlibError};
use std::f64::consts::{E, PI};

/// Absolute value
pub fn abs(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    match &args[0] {
        Value::Int(n) => Ok(Value::Int(n.abs())),
        Value::Float(n) => Ok(Value::Float(n.abs())),
        other => Err(StdlibError::TypeError {
            expected: "Int or Float".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

/// Square root
pub fn sqrt(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let n = expect_float(&args[0], "n")?;
    if n < 0.0 {
        Err(StdlibError::RuntimeError(
            "Cannot take square root of negative number".to_string(),
        ))
    } else {
        Ok(Value::Float(n.sqrt()))
    }
}

/// Power function
pub fn pow(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let base = expect_float(&args[0], "base")?;
    let exp = expect_float(&args[1], "exponent")?;
    Ok(Value::Float(base.powf(exp)))
}

/// Sine function (radians)
pub fn sin(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let n = expect_float(&args[0], "n")?;
    Ok(Value::Float(n.sin()))
}

/// Cosine function (radians)
pub fn cos(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let n = expect_float(&args[0], "n")?;
    Ok(Value::Float(n.cos()))
}

/// Tangent function (radians)
pub fn tan(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let n = expect_float(&args[0], "n")?;
    Ok(Value::Float(n.tan()))
}

/// Floor function
pub fn floor(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let n = expect_float(&args[0], "n")?;
    Ok(Value::Int(n.floor() as i64))
}

/// Ceiling function
pub fn ceil(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let n = expect_float(&args[0], "n")?;
    Ok(Value::Int(n.ceil() as i64))
}

/// Round function
pub fn round(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let n = expect_float(&args[0], "n")?;
    Ok(Value::Int(n.round() as i64))
}

/// Minimum of two values
pub fn min(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    match (&args[0], &args[1]) {
        (Value::Int(a), Value::Int(b)) => Ok(Value::Int(*a.min(b))),
        (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a.min(*b))),
        (Value::Int(a), Value::Float(b)) => Ok(Value::Float((*a as f64).min(*b))),
        (Value::Float(a), Value::Int(b)) => Ok(Value::Float(a.min(*b as f64))),
        _ => Err(StdlibError::TypeError {
            expected: "Int or Float".to_string(),
            got: "non-numeric".to_string(),
        }),
    }
}

/// Maximum of two values
pub fn max(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    match (&args[0], &args[1]) {
        (Value::Int(a), Value::Int(b)) => Ok(Value::Int(*a.max(b))),
        (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a.max(*b))),
        (Value::Int(a), Value::Float(b)) => Ok(Value::Float((*a as f64).max(*b))),
        (Value::Float(a), Value::Int(b)) => Ok(Value::Float(a.max(*b as f64))),
        _ => Err(StdlibError::TypeError {
            expected: "Int or Float".to_string(),
            got: "non-numeric".to_string(),
        }),
    }
}

/// Random number between 0 and 1 (or between min and max if provided)
pub fn random(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity_range(args, 0, 2)?;

    // Simple pseudo-random using system time
    use std::time::{SystemTime, UNIX_EPOCH};
    let seed = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);

    // Simple LCG
    let random_val = ((seed.wrapping_mul(1103515245).wrapping_add(12345)) % (1 << 31)) as f64 / (1u64 << 31) as f64;

    match args.len() {
        0 => Ok(Value::Float(random_val)),
        2 => {
            let min = expect_float(&args[0], "min")?;
            let max = expect_float(&args[1], "max")?;
            Ok(Value::Float(min + random_val * (max - min)))
        }
        _ => Err(StdlibError::ArityError { expected: 0, got: args.len() }),
    }
}

/// Pi constant
pub fn pi(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 0)?;
    Ok(Value::Float(PI))
}

/// E constant (Euler's number)
pub fn e(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 0)?;
    Ok(Value::Float(E))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_caps() -> CapabilityRegistry {
        CapabilityRegistry::permissive()
    }

    #[test]
    fn test_abs() {
        let mut caps = test_caps();
        assert_eq!(
            abs(&[Value::Int(-5)], &mut caps).unwrap(),
            Value::Int(5)
        );
        assert_eq!(
            abs(&[Value::Float(-3.14)], &mut caps).unwrap(),
            Value::Float(3.14)
        );
    }

    #[test]
    fn test_sqrt() {
        let mut caps = test_caps();
        assert_eq!(
            sqrt(&[Value::Int(16)], &mut caps).unwrap(),
            Value::Float(4.0)
        );
        assert!(sqrt(&[Value::Int(-1)], &mut caps).is_err());
    }

    #[test]
    fn test_pow() {
        let mut caps = test_caps();
        assert_eq!(
            pow(&[Value::Int(2), Value::Int(3)], &mut caps).unwrap(),
            Value::Float(8.0)
        );
    }

    #[test]
    fn test_floor_ceil_round() {
        let mut caps = test_caps();
        assert_eq!(
            floor(&[Value::Float(3.7)], &mut caps).unwrap(),
            Value::Int(3)
        );
        assert_eq!(
            ceil(&[Value::Float(3.2)], &mut caps).unwrap(),
            Value::Int(4)
        );
        assert_eq!(
            round(&[Value::Float(3.5)], &mut caps).unwrap(),
            Value::Int(4)
        );
    }

    #[test]
    fn test_min_max() {
        let mut caps = test_caps();
        assert_eq!(
            min(&[Value::Int(3), Value::Int(7)], &mut caps).unwrap(),
            Value::Int(3)
        );
        assert_eq!(
            max(&[Value::Int(3), Value::Int(7)], &mut caps).unwrap(),
            Value::Int(7)
        );
    }

    #[test]
    fn test_constants() {
        let mut caps = test_caps();
        assert_eq!(pi(&[], &mut caps).unwrap(), Value::Float(PI));
        assert_eq!(e(&[], &mut caps).unwrap(), Value::Float(E));
    }
}
