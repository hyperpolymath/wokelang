// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

const std = @import("std");
const testing = std.testing;
const woke = @import("../src/main.zig");

test "interpreter lifecycle" {
    const interp = woke.woke_interpreter_new();
    try testing.expect(interp != null);
    defer woke.woke_interpreter_free(interp);
}

test "execute simple code" {
    const interp = woke.woke_interpreter_new() orelse return error.InitFailed;
    defer woke.woke_interpreter_free(interp);

    const result = woke.woke_exec(interp, "remember x = 42;");
    try testing.expectEqual(woke.Result.ok, result);
}

test "eval expression" {
    const interp = woke.woke_interpreter_new() orelse return error.InitFailed;
    defer woke.woke_interpreter_free(interp);

    var value: ?*woke.ValueHandle = null;
    const result = woke.woke_eval(interp, "5 + 3", &value);
    try testing.expectEqual(woke.Result.ok, result);

    if (value) |v| {
        defer woke.woke_value_free(v);

        const vtype = woke.woke_value_type(v);
        try testing.expectEqual(woke.ValueType.int, vtype);

        var int_val: i64 = 0;
        const int_result = woke.woke_value_as_int(v, &int_val);
        try testing.expectEqual(woke.Result.ok, int_result);
        try testing.expectEqual(@as(i64, 8), int_val);
    }
}

test "value creation" {
    const int_val = woke.woke_value_from_int(42);
    try testing.expect(int_val != null);
    defer woke.woke_value_free(int_val);

    const float_val = woke.woke_value_from_float(3.14);
    try testing.expect(float_val != null);
    defer woke.woke_value_free(float_val);

    const bool_val = woke.woke_value_from_bool(1);
    try testing.expect(bool_val != null);
    defer woke.woke_value_free(bool_val);
}

test "version string" {
    const version = woke.woke_version();
    try testing.expect(version[0] != 0); // Not empty
}

test "null pointer safety" {
    const result = woke.woke_exec(null, "code");
    try testing.expectEqual(woke.Result.null_pointer, result);
}
