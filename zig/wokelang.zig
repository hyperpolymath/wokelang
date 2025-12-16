//! WokeLang FFI bindings for Zig
//!
//! This module provides Zig-native bindings to the WokeLang interpreter.
//!
//! Example usage:
//! ```zig
//! const woke = @import("wokelang.zig");
//!
//! pub fn main() !void {
//!     var interp = woke.Interpreter.init() orelse return error.InitFailed;
//!     defer interp.deinit();
//!
//!     try interp.exec(
//!         \\to greet(name: String) -> String {
//!         \\    give back "Hello, " + name + "!";
//!         \\}
//!     );
//! }
//! ```

const std = @import("std");

/// Result codes from WokeLang FFI operations
pub const Result = enum(c_int) {
    ok = 0,
    @"error" = 1,
    parse_error = 2,
    runtime_error = 3,
    null_pointer = 4,

    pub fn isOk(self: Result) bool {
        return self == .ok;
    }

    pub fn toError(self: Result) ?Error {
        return switch (self) {
            .ok => null,
            .@"error" => Error.GenericError,
            .parse_error => Error.ParseError,
            .runtime_error => Error.RuntimeError,
            .null_pointer => Error.NullPointer,
        };
    }
};

/// Value type tags
pub const ValueType = enum(c_int) {
    int = 0,
    float = 1,
    string = 2,
    bool = 3,
    array = 4,
    unit = 5,
};

/// Errors that can occur when using the WokeLang FFI
pub const Error = error{
    GenericError,
    ParseError,
    RuntimeError,
    NullPointer,
    InitFailed,
};

// === External C API declarations ===

const WokeInterpreter = opaque {};
const WokeValue = opaque {};

extern fn woke_interpreter_new() ?*WokeInterpreter;
extern fn woke_interpreter_free(interp: *WokeInterpreter) void;
extern fn woke_exec(interp: *WokeInterpreter, source: [*:0]const u8) Result;
extern fn woke_eval(interp: *WokeInterpreter, source: [*:0]const u8, out_value: *?*WokeValue) Result;

extern fn woke_value_free(value: *WokeValue) void;
extern fn woke_value_type(value: *const WokeValue) ValueType;
extern fn woke_value_as_int(value: *const WokeValue, out: *i64) Result;
extern fn woke_value_as_float(value: *const WokeValue, out: *f64) Result;
extern fn woke_value_as_bool(value: *const WokeValue, out: *c_int) Result;
extern fn woke_value_as_string(value: *const WokeValue) ?[*:0]u8;
extern fn woke_string_free(s: [*:0]u8) void;

extern fn woke_value_from_int(n: i64) ?*WokeValue;
extern fn woke_value_from_float(f: f64) ?*WokeValue;
extern fn woke_value_from_bool(b: c_int) ?*WokeValue;
extern fn woke_value_from_string(s: [*:0]const u8) ?*WokeValue;

extern fn woke_version() [*:0]const u8;
extern fn woke_last_error() ?[*:0]const u8;

// === High-level Zig API ===

/// A WokeLang interpreter instance
pub const Interpreter = struct {
    handle: *WokeInterpreter,

    /// Initialize a new WokeLang interpreter
    pub fn init() ?Interpreter {
        const handle = woke_interpreter_new() orelse return null;
        return .{ .handle = handle };
    }

    /// Clean up the interpreter
    pub fn deinit(self: *Interpreter) void {
        woke_interpreter_free(self.handle);
    }

    /// Execute WokeLang source code
    pub fn exec(self: *Interpreter, source: [:0]const u8) Error!void {
        const result = woke_exec(self.handle, source.ptr);
        if (result.toError()) |err| {
            return err;
        }
    }

    /// Execute WokeLang source code (string literal version)
    pub fn execLiteral(self: *Interpreter, comptime source: [:0]const u8) Error!void {
        return self.exec(source);
    }

    /// Evaluate an expression and get the result
    pub fn eval(self: *Interpreter, source: [:0]const u8) Error!Value {
        var out_value: ?*WokeValue = null;
        const result = woke_eval(self.handle, source.ptr, &out_value);
        if (result.toError()) |err| {
            return err;
        }
        return Value{ .handle = out_value.? };
    }
};

/// A WokeLang value
pub const Value = struct {
    handle: *WokeValue,

    /// Free the value
    pub fn deinit(self: *Value) void {
        woke_value_free(self.handle);
    }

    /// Get the type of the value
    pub fn getType(self: Value) ValueType {
        return woke_value_type(self.handle);
    }

    /// Get as integer
    pub fn asInt(self: Value) Error!i64 {
        var out: i64 = 0;
        const result = woke_value_as_int(self.handle, &out);
        if (result.toError()) |err| {
            return err;
        }
        return out;
    }

    /// Get as float
    pub fn asFloat(self: Value) Error!f64 {
        var out: f64 = 0;
        const result = woke_value_as_float(self.handle, &out);
        if (result.toError()) |err| {
            return err;
        }
        return out;
    }

    /// Get as boolean
    pub fn asBool(self: Value) Error!bool {
        var out: c_int = 0;
        const result = woke_value_as_bool(self.handle, &out);
        if (result.toError()) |err| {
            return err;
        }
        return out != 0;
    }

    /// Get as string (allocates)
    pub fn asString(self: Value, allocator: std.mem.Allocator) Error![]u8 {
        const c_str = woke_value_as_string(self.handle) orelse return Error.NullPointer;
        defer woke_string_free(c_str);

        const len = std.mem.len(c_str);
        const buf = allocator.alloc(u8, len) catch return Error.GenericError;
        @memcpy(buf, c_str[0..len]);
        return buf;
    }

    /// Create from integer
    pub fn fromInt(n: i64) ?Value {
        const handle = woke_value_from_int(n) orelse return null;
        return .{ .handle = handle };
    }

    /// Create from float
    pub fn fromFloat(f: f64) ?Value {
        const handle = woke_value_from_float(f) orelse return null;
        return .{ .handle = handle };
    }

    /// Create from boolean
    pub fn fromBool(b: bool) ?Value {
        const handle = woke_value_from_bool(if (b) 1 else 0) orelse return null;
        return .{ .handle = handle };
    }

    /// Create from string
    pub fn fromString(s: [:0]const u8) ?Value {
        const handle = woke_value_from_string(s.ptr) orelse return null;
        return .{ .handle = handle };
    }
};

/// Get the WokeLang version string
pub fn version() []const u8 {
    const ver = woke_version();
    return std.mem.span(ver);
}

/// Get the last error message (if any)
pub fn lastError() ?[]const u8 {
    const err = woke_last_error() orelse return null;
    return std.mem.span(err);
}

// === Tests ===

test "version" {
    const ver = version();
    try std.testing.expectEqualStrings("0.1.0", ver);
}
