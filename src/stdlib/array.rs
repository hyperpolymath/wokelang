//! WokeLang Standard Library - Array Module
//!
//! Array manipulation functions.

use crate::interpreter::Value;
use crate::security::CapabilityRegistry;
use super::{check_arity, check_arity_range, expect_int, StdlibError};

/// Get the length of an array
pub fn length(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    match &args[0] {
        Value::Array(a) => Ok(Value::Int(a.len() as i64)),
        other => Err(StdlibError::TypeError {
            expected: "Array".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

/// Check if array is empty
pub fn is_empty(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    match &args[0] {
        Value::Array(a) => Ok(Value::Bool(a.is_empty())),
        other => Err(StdlibError::TypeError {
            expected: "Array".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

/// Get first element of array
pub fn first(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    match &args[0] {
        Value::Array(a) => match a.first() {
            Some(v) => Ok(Value::Okay(Box::new(v.clone()))),
            None => Ok(Value::Oops("array is empty".to_string())),
        },
        other => Err(StdlibError::TypeError {
            expected: "Array".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

/// Get last element of array
pub fn last(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    match &args[0] {
        Value::Array(a) => match a.last() {
            Some(v) => Ok(Value::Okay(Box::new(v.clone()))),
            None => Ok(Value::Oops("array is empty".to_string())),
        },
        other => Err(StdlibError::TypeError {
            expected: "Array".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

/// Push element to array (returns new array)
pub fn push(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    match &args[0] {
        Value::Array(a) => {
            let mut new_arr = a.clone();
            new_arr.push(args[1].clone());
            Ok(Value::Array(new_arr))
        }
        other => Err(StdlibError::TypeError {
            expected: "Array".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

/// Pop last element from array (returns [new_array, popped_element])
pub fn pop(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    match &args[0] {
        Value::Array(a) => {
            if a.is_empty() {
                Ok(Value::Oops("array is empty".to_string()))
            } else {
                let mut new_arr = a.clone();
                let popped = new_arr.pop().unwrap();
                Ok(Value::Array(vec![Value::Array(new_arr), popped]))
            }
        }
        other => Err(StdlibError::TypeError {
            expected: "Array".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

/// Concatenate two arrays
pub fn concat(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    let arr1 = match &args[0] {
        Value::Array(a) => a,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Array".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    let arr2 = match &args[1] {
        Value::Array(a) => a,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Array".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    let mut result = arr1.clone();
    result.extend(arr2.clone());
    Ok(Value::Array(result))
}

/// Reverse an array
pub fn reverse(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    match &args[0] {
        Value::Array(a) => {
            let mut new_arr = a.clone();
            new_arr.reverse();
            Ok(Value::Array(new_arr))
        }
        other => Err(StdlibError::TypeError {
            expected: "Array".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

/// Get slice of array
pub fn slice(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity_range(args, 2, 3)?;

    let arr = match &args[0] {
        Value::Array(a) => a,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Array".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    let len = arr.len() as i64;
    let start = expect_int(&args[1], "start")?;

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
        return Ok(Value::Array(vec![]));
    }

    Ok(Value::Array(arr[start_idx..end_idx].to_vec()))
}

/// Check if array contains a value
pub fn contains(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
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

    Ok(Value::Bool(arr.contains(&args[1])))
}

/// Find index of first occurrence of value
pub fn index_of(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
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

    match arr.iter().position(|x| x == &args[1]) {
        Some(idx) => Ok(Value::Int(idx as i64)),
        None => Ok(Value::Int(-1)),
    }
}

/// Create array of repeated value
pub fn repeat(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let count = expect_int(&args[1], "count")?;

    if count < 0 {
        return Err(StdlibError::RuntimeError("repeat count cannot be negative".to_string()));
    }

    if count > 10000 {
        return Err(StdlibError::RuntimeError("repeat count too large (max 10000)".to_string()));
    }

    let arr: Vec<Value> = std::iter::repeat(args[0].clone()).take(count as usize).collect();
    Ok(Value::Array(arr))
}

/// Create a range array from start to end (exclusive)
pub fn range(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity_range(args, 1, 3)?;

    let (start, end, step) = if args.len() == 1 {
        (0, expect_int(&args[0], "end")?, 1)
    } else if args.len() == 2 {
        (expect_int(&args[0], "start")?, expect_int(&args[1], "end")?, 1)
    } else {
        (
            expect_int(&args[0], "start")?,
            expect_int(&args[1], "end")?,
            expect_int(&args[2], "step")?,
        )
    };

    if step == 0 {
        return Err(StdlibError::RuntimeError("step cannot be zero".to_string()));
    }

    // Limit array size to prevent memory exhaustion
    let estimated_size = if step > 0 {
        ((end - start) / step).max(0) as usize
    } else {
        ((start - end) / (-step)).max(0) as usize
    };

    if estimated_size > 100000 {
        return Err(StdlibError::RuntimeError("range too large (max 100000)".to_string()));
    }

    let arr: Vec<Value> = if step > 0 {
        (start..end).step_by(step as usize).map(Value::Int).collect()
    } else {
        let mut result = Vec::new();
        let mut i = start;
        while i > end {
            result.push(Value::Int(i));
            i += step;
        }
        result
    };

    Ok(Value::Array(arr))
}

/// Flatten nested arrays one level
pub fn flatten(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;

    let arr = match &args[0] {
        Value::Array(a) => a,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Array".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    let mut result = Vec::new();
    for item in arr {
        match item {
            Value::Array(inner) => result.extend(inner.clone()),
            other => result.push(other.clone()),
        }
    }

    Ok(Value::Array(result))
}

/// Remove duplicates from array (preserves first occurrence)
pub fn unique(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;

    let arr = match &args[0] {
        Value::Array(a) => a,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Array".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    let mut result = Vec::new();
    for item in arr {
        if !result.contains(item) {
            result.push(item.clone());
        }
    }

    Ok(Value::Array(result))
}

/// Zip two arrays together
pub fn zip(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    let arr1 = match &args[0] {
        Value::Array(a) => a,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Array".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    let arr2 = match &args[1] {
        Value::Array(a) => a,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Array".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    let result: Vec<Value> = arr1
        .iter()
        .zip(arr2.iter())
        .map(|(a, b)| Value::Array(vec![a.clone(), b.clone()]))
        .collect();

    Ok(Value::Array(result))
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
        let arr = Value::Array(vec![Value::Int(1), Value::Int(2), Value::Int(3)]);
        assert_eq!(length(&[arr], &mut caps).unwrap(), Value::Int(3));
    }

    #[test]
    fn test_first_last() {
        let mut caps = test_caps();
        let arr = Value::Array(vec![Value::Int(1), Value::Int(2), Value::Int(3)]);

        if let Value::Okay(v) = first(&[arr.clone()], &mut caps).unwrap() {
            assert_eq!(*v, Value::Int(1));
        }

        if let Value::Okay(v) = last(&[arr], &mut caps).unwrap() {
            assert_eq!(*v, Value::Int(3));
        }
    }

    #[test]
    fn test_push_pop() {
        let mut caps = test_caps();
        let arr = Value::Array(vec![Value::Int(1), Value::Int(2)]);

        let pushed = push(&[arr, Value::Int(3)], &mut caps).unwrap();
        assert_eq!(
            pushed,
            Value::Array(vec![Value::Int(1), Value::Int(2), Value::Int(3)])
        );
    }

    #[test]
    fn test_concat() {
        let mut caps = test_caps();
        let arr1 = Value::Array(vec![Value::Int(1), Value::Int(2)]);
        let arr2 = Value::Array(vec![Value::Int(3), Value::Int(4)]);

        assert_eq!(
            concat(&[arr1, arr2], &mut caps).unwrap(),
            Value::Array(vec![
                Value::Int(1),
                Value::Int(2),
                Value::Int(3),
                Value::Int(4)
            ])
        );
    }

    #[test]
    fn test_slice() {
        let mut caps = test_caps();
        let arr = Value::Array(vec![
            Value::Int(1),
            Value::Int(2),
            Value::Int(3),
            Value::Int(4),
        ]);

        assert_eq!(
            slice(&[arr, Value::Int(1), Value::Int(3)], &mut caps).unwrap(),
            Value::Array(vec![Value::Int(2), Value::Int(3)])
        );
    }

    #[test]
    fn test_range() {
        let mut caps = test_caps();

        assert_eq!(
            range(&[Value::Int(5)], &mut caps).unwrap(),
            Value::Array(vec![
                Value::Int(0),
                Value::Int(1),
                Value::Int(2),
                Value::Int(3),
                Value::Int(4)
            ])
        );

        assert_eq!(
            range(&[Value::Int(2), Value::Int(5)], &mut caps).unwrap(),
            Value::Array(vec![Value::Int(2), Value::Int(3), Value::Int(4)])
        );
    }

    #[test]
    fn test_unique() {
        let mut caps = test_caps();
        let arr = Value::Array(vec![
            Value::Int(1),
            Value::Int(2),
            Value::Int(1),
            Value::Int(3),
            Value::Int(2),
        ]);

        assert_eq!(
            unique(&[arr], &mut caps).unwrap(),
            Value::Array(vec![Value::Int(1), Value::Int(2), Value::Int(3)])
        );
    }

    #[test]
    fn test_zip() {
        let mut caps = test_caps();
        let arr1 = Value::Array(vec![Value::Int(1), Value::Int(2)]);
        let arr2 = Value::Array(vec![
            Value::String("a".to_string()),
            Value::String("b".to_string()),
        ]);

        assert_eq!(
            zip(&[arr1, arr2], &mut caps).unwrap(),
            Value::Array(vec![
                Value::Array(vec![Value::Int(1), Value::String("a".to_string())]),
                Value::Array(vec![Value::Int(2), Value::String("b".to_string())]),
            ])
        );
    }
}
