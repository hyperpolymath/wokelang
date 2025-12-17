//! C-compatible API for WokeLang
//!
//! This module provides extern "C" functions that can be called from Zig, C,
//! or any language supporting the C ABI.

use crate::interpreter::{Interpreter, Value};
use crate::lexer::Lexer;
use crate::parser::Parser;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_double, c_int, c_longlong};
use std::ptr;

/// Opaque handle to a WokeLang interpreter instance
pub struct WokeInterpreter {
    inner: Interpreter,
}

/// Opaque handle to a WokeLang value
pub struct WokeValue {
    inner: Value,
}

/// Result code for FFI operations
#[repr(C)]
pub enum WokeResult {
    Ok = 0,
    Error = 1,
    ParseError = 2,
    RuntimeError = 3,
    NullPointer = 4,
}

/// Value type tag for FFI
#[repr(C)]
pub enum WokeValueType {
    Int = 0,
    Float = 1,
    String = 2,
    Bool = 3,
    Array = 4,
    Unit = 5,
    Okay = 6,
    Oops = 7,
    Record = 8,
}

// === Interpreter lifecycle ===

/// Create a new WokeLang interpreter
///
/// Returns a pointer to the interpreter, or null on failure.
/// The caller is responsible for freeing with `woke_interpreter_free`.
#[no_mangle]
pub extern "C" fn woke_interpreter_new() -> *mut WokeInterpreter {
    Box::into_raw(Box::new(WokeInterpreter {
        inner: Interpreter::new(),
    }))
}

/// Free a WokeLang interpreter
///
/// # Safety
/// The pointer must be valid and not null.
#[no_mangle]
pub unsafe extern "C" fn woke_interpreter_free(interp: *mut WokeInterpreter) {
    if !interp.is_null() {
        drop(Box::from_raw(interp));
    }
}

/// Execute WokeLang source code
///
/// # Safety
/// - `interp` must be a valid pointer from `woke_interpreter_new`
/// - `source` must be a valid null-terminated C string
#[no_mangle]
pub unsafe extern "C" fn woke_exec(interp: *mut WokeInterpreter, source: *const c_char) -> WokeResult {
    if interp.is_null() || source.is_null() {
        return WokeResult::NullPointer;
    }

    let interp = &mut *interp;
    let source = match CStr::from_ptr(source).to_str() {
        Ok(s) => s,
        Err(_) => return WokeResult::Error,
    };

    let lexer = Lexer::new(source);
    let tokens = match lexer.tokenize() {
        Ok(t) => t,
        Err(_) => return WokeResult::ParseError,
    };

    let mut parser = Parser::new(tokens, source);
    let program = match parser.parse() {
        Ok(p) => p,
        Err(_) => return WokeResult::ParseError,
    };

    match interp.inner.run(&program) {
        Ok(_) => WokeResult::Ok,
        Err(_) => WokeResult::RuntimeError,
    }
}

/// Execute WokeLang source and get return value
///
/// # Safety
/// - All pointers must be valid
/// - The returned WokeValue must be freed with `woke_value_free`
#[no_mangle]
pub unsafe extern "C" fn woke_eval(
    interp: *mut WokeInterpreter,
    source: *const c_char,
    out_value: *mut *mut WokeValue,
) -> WokeResult {
    if interp.is_null() || source.is_null() || out_value.is_null() {
        return WokeResult::NullPointer;
    }

    let interp = &mut *interp;
    let source = match CStr::from_ptr(source).to_str() {
        Ok(s) => s,
        Err(_) => return WokeResult::Error,
    };

    // Wrap the expression in a function that returns it
    let wrapped = format!(
        "to __ffi_eval__() {{ give back {}; }} to main() {{ __ffi_eval__(); }}",
        source.trim_end_matches(';')
    );

    let lexer = Lexer::new(&wrapped);
    let tokens = match lexer.tokenize() {
        Ok(t) => t,
        Err(_) => return WokeResult::ParseError,
    };

    let mut parser = Parser::new(tokens, &wrapped);
    let program = match parser.parse() {
        Ok(p) => p,
        Err(_) => return WokeResult::ParseError,
    };

    match interp.inner.run(&program) {
        Ok(_) => {
            // Return unit value for now (full implementation would capture return value)
            *out_value = Box::into_raw(Box::new(WokeValue { inner: Value::Unit }));
            WokeResult::Ok
        }
        Err(_) => WokeResult::RuntimeError,
    }
}

// === Value operations ===

/// Free a WokeValue
///
/// # Safety
/// The pointer must be valid and from a woke_* function.
#[no_mangle]
pub unsafe extern "C" fn woke_value_free(value: *mut WokeValue) {
    if !value.is_null() {
        drop(Box::from_raw(value));
    }
}

/// Get the type of a WokeValue
#[no_mangle]
pub unsafe extern "C" fn woke_value_type(value: *const WokeValue) -> WokeValueType {
    if value.is_null() {
        return WokeValueType::Unit;
    }

    match &(*value).inner {
        Value::Int(_) => WokeValueType::Int,
        Value::Float(_) => WokeValueType::Float,
        Value::String(_) => WokeValueType::String,
        Value::Bool(_) => WokeValueType::Bool,
        Value::Array(_) => WokeValueType::Array,
        Value::Record(_) => WokeValueType::Record,
        Value::Unit => WokeValueType::Unit,
        Value::Okay(_) => WokeValueType::Okay,
        Value::Oops(_) => WokeValueType::Oops,
    }
}

/// Get an integer from a WokeValue
#[no_mangle]
pub unsafe extern "C" fn woke_value_as_int(value: *const WokeValue, out: *mut c_longlong) -> WokeResult {
    if value.is_null() || out.is_null() {
        return WokeResult::NullPointer;
    }

    match &(*value).inner {
        Value::Int(n) => {
            *out = *n;
            WokeResult::Ok
        }
        _ => WokeResult::Error,
    }
}

/// Get a float from a WokeValue
#[no_mangle]
pub unsafe extern "C" fn woke_value_as_float(value: *const WokeValue, out: *mut c_double) -> WokeResult {
    if value.is_null() || out.is_null() {
        return WokeResult::NullPointer;
    }

    match &(*value).inner {
        Value::Float(f) => {
            *out = *f;
            WokeResult::Ok
        }
        Value::Int(n) => {
            *out = *n as c_double;
            WokeResult::Ok
        }
        _ => WokeResult::Error,
    }
}

/// Get a boolean from a WokeValue
#[no_mangle]
pub unsafe extern "C" fn woke_value_as_bool(value: *const WokeValue, out: *mut c_int) -> WokeResult {
    if value.is_null() || out.is_null() {
        return WokeResult::NullPointer;
    }

    match &(*value).inner {
        Value::Bool(b) => {
            *out = if *b { 1 } else { 0 };
            WokeResult::Ok
        }
        _ => WokeResult::Error,
    }
}

/// Get a string from a WokeValue
///
/// The returned string must be freed with `woke_string_free`.
#[no_mangle]
pub unsafe extern "C" fn woke_value_as_string(value: *const WokeValue) -> *mut c_char {
    if value.is_null() {
        return ptr::null_mut();
    }

    match &(*value).inner {
        Value::String(s) => match CString::new(s.as_str()) {
            Ok(cs) => cs.into_raw(),
            Err(_) => ptr::null_mut(),
        },
        other => match CString::new(other.to_string()) {
            Ok(cs) => cs.into_raw(),
            Err(_) => ptr::null_mut(),
        },
    }
}

/// Free a string returned by woke_value_as_string
#[no_mangle]
pub unsafe extern "C" fn woke_string_free(s: *mut c_char) {
    if !s.is_null() {
        drop(CString::from_raw(s));
    }
}

// === Value creation ===

/// Create an integer WokeValue
#[no_mangle]
pub extern "C" fn woke_value_from_int(n: c_longlong) -> *mut WokeValue {
    Box::into_raw(Box::new(WokeValue {
        inner: Value::Int(n),
    }))
}

/// Create a float WokeValue
#[no_mangle]
pub extern "C" fn woke_value_from_float(f: c_double) -> *mut WokeValue {
    Box::into_raw(Box::new(WokeValue {
        inner: Value::Float(f),
    }))
}

/// Create a boolean WokeValue
#[no_mangle]
pub extern "C" fn woke_value_from_bool(b: c_int) -> *mut WokeValue {
    Box::into_raw(Box::new(WokeValue {
        inner: Value::Bool(b != 0),
    }))
}

/// Create a string WokeValue
///
/// # Safety
/// `s` must be a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn woke_value_from_string(s: *const c_char) -> *mut WokeValue {
    if s.is_null() {
        return ptr::null_mut();
    }

    match CStr::from_ptr(s).to_str() {
        Ok(str) => Box::into_raw(Box::new(WokeValue {
            inner: Value::String(str.to_string()),
        })),
        Err(_) => ptr::null_mut(),
    }
}

// === Utility ===

/// Get the WokeLang version string
#[no_mangle]
pub extern "C" fn woke_version() -> *const c_char {
    static VERSION: &[u8] = b"0.1.0\0";
    VERSION.as_ptr() as *const c_char
}

/// Get the last error message (if any)
///
/// Returns null if no error. The returned string is valid until the next woke_* call.
#[no_mangle]
pub extern "C" fn woke_last_error() -> *const c_char {
    // TODO: Implement thread-local error storage
    ptr::null()
}
