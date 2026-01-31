// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
//! WokeLang Zig FFI Implementation
//!
//! This module provides C-compatible FFI functions that bridge between
//! the Idris2 ABI definitions and the Rust implementation.

const std = @import("std");

// ==== Opaque Types ====

pub const InterpreterHandle = opaque {};
pub const ValueHandle = opaque {};

// ==== Result Codes ====

pub const Result = enum(c_int) {
    ok = 0,
    @"error" = 1,
    parse_error = 2,
    runtime_error = 3,
    null_pointer = 4,
};

// ==== Value Types ====

pub const ValueType = enum(c_int) {
    int = 0,
    float = 1,
    string = 2,
    bool = 3,
    array = 4,
    unit = 5,
};

// ==== Interpreter Lifecycle ====

/// Create a new WokeLang interpreter
/// Returns null on failure
export fn woke_interpreter_new() ?*InterpreterHandle {
    // Implementation calls Rust FFI
    return rust_woke_interpreter_new();
}

/// Free a WokeLang interpreter
export fn woke_interpreter_free(interp: ?*InterpreterHandle) void {
    if (interp) |ptr| {
        rust_woke_interpreter_free(ptr);
    }
}

// ==== Execution ====

/// Execute WokeLang source code
export fn woke_exec(interp: ?*InterpreterHandle, source: [*:0]const u8) Result {
    if (interp == null or source == null) {
        return .null_pointer;
    }
    return rust_woke_exec(interp.?, source);
}

/// Execute and get return value
export fn woke_eval(
    interp: ?*InterpreterHandle,
    source: [*:0]const u8,
    out_value: ?*?*ValueHandle,
) Result {
    if (interp == null or source == null or out_value == null) {
        return .null_pointer;
    }
    return rust_woke_eval(interp.?, source, out_value.?);
}

// ==== Value Operations ====

/// Free a WokeLang value
export fn woke_value_free(value: ?*ValueHandle) void {
    if (value) |ptr| {
        rust_woke_value_free(ptr);
    }
}

/// Get value type
export fn woke_value_type(value: ?*const ValueHandle) ValueType {
    if (value) |ptr| {
        return rust_woke_value_type(ptr);
    }
    return .unit;
}

/// Get integer from value
export fn woke_value_as_int(value: ?*const ValueHandle, out: ?*i64) Result {
    if (value == null or out == null) {
        return .null_pointer;
    }
    return rust_woke_value_as_int(value.?, out.?);
}

/// Get float from value
export fn woke_value_as_float(value: ?*const ValueHandle, out: ?*f64) Result {
    if (value == null or out == null) {
        return .null_pointer;
    }
    return rust_woke_value_as_float(value.?, out.?);
}

/// Get boolean from value
export fn woke_value_as_bool(value: ?*const ValueHandle, out: ?*c_int) Result {
    if (value == null or out == null) {
        return .null_pointer;
    }
    return rust_woke_value_as_bool(value.?, out.?);
}

/// Get string from value (must free with woke_string_free)
export fn woke_value_as_string(value: ?*const ValueHandle) ?[*:0]u8 {
    if (value) |ptr| {
        return rust_woke_value_as_string(ptr);
    }
    return null;
}

/// Free string returned by woke_value_as_string
export fn woke_string_free(s: ?[*:0]u8) void {
    if (s) |ptr| {
        rust_woke_string_free(ptr);
    }
}

// ==== Value Creation ====

/// Create integer value
export fn woke_value_from_int(n: i64) ?*ValueHandle {
    return rust_woke_value_from_int(n);
}

/// Create float value
export fn woke_value_from_float(f: f64) ?*ValueHandle {
    return rust_woke_value_from_float(f);
}

/// Create boolean value
export fn woke_value_from_bool(b: c_int) ?*ValueHandle {
    return rust_woke_value_from_bool(b);
}

/// Create string value
export fn woke_value_from_string(s: [*:0]const u8) ?*ValueHandle {
    return rust_woke_value_from_string(s);
}

// ==== Utility ====

/// Get version string
export fn woke_version() [*:0]const u8 {
    return rust_woke_version();
}

/// Get last error message
export fn woke_last_error() ?[*:0]const u8 {
    return rust_woke_last_error();
}

// ==== Rust FFI Declarations ====
// These link to the existing Rust implementation

extern "C" fn rust_woke_interpreter_new() ?*InterpreterHandle;
extern "C" fn rust_woke_interpreter_free(interp: *InterpreterHandle) void;
extern "C" fn rust_woke_exec(interp: *InterpreterHandle, source: [*:0]const u8) Result;
extern "C" fn rust_woke_eval(interp: *InterpreterHandle, source: [*:0]const u8, out: *?*ValueHandle) Result;
extern "C" fn rust_woke_value_free(value: *ValueHandle) void;
extern "C" fn rust_woke_value_type(value: *const ValueHandle) ValueType;
extern "C" fn rust_woke_value_as_int(value: *const ValueHandle, out: *i64) Result;
extern "C" fn rust_woke_value_as_float(value: *const ValueHandle, out: *f64) Result;
extern "C" fn rust_woke_value_as_bool(value: *const ValueHandle, out: *c_int) Result;
extern "C" fn rust_woke_value_as_string(value: *const ValueHandle) ?[*:0]u8;
extern "C" fn rust_woke_string_free(s: [*:0]u8) void;
extern "C" fn rust_woke_value_from_int(n: i64) ?*ValueHandle;
extern "C" fn rust_woke_value_from_float(f: f64) ?*ValueHandle;
extern "C" fn rust_woke_value_from_bool(b: c_int) ?*ValueHandle;
extern "C" fn rust_woke_value_from_string(s: [*:0]const u8) ?*ValueHandle;
extern "C" fn rust_woke_version() [*:0]const u8;
extern "C" fn rust_woke_last_error() ?[*:0]const u8;
