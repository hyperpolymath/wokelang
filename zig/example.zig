//! Example of using WokeLang from Zig
//!
//! Build with: zig build
//! Run with: zig build run

const std = @import("std");
const woke = @import("wokelang.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // Print version
    try stdout.print("WokeLang version: {s}\n\n", .{woke.version()});

    // Create interpreter
    var interp = woke.Interpreter.init() orelse {
        try stdout.print("Failed to create interpreter\n", .{});
        return;
    };
    defer interp.deinit();

    // Define some WokeLang functions
    const woke_code =
        \\// Math functions defined in WokeLang
        \\to add(a: Int, b: Int) -> Int {
        \\    give back a + b;
        \\}
        \\
        \\to multiply(a: Int, b: Int) -> Int {
        \\    give back a * b;
        \\}
        \\
        \\to factorial(n: Int) -> Int {
        \\    when n <= 1 {
        \\        give back 1;
        \\    }
        \\    give back n * factorial(n - 1);
        \\}
        \\
        \\to greet(name: String) {
        \\    print("Hello, " + name + "!");
        \\}
        \\
        \\to main() {
        \\    greet("Zig");
        \\    print("5! = " + toString(factorial(5)));
        \\    print("3 + 4 = " + toString(add(3, 4)));
        \\}
    ;

    try stdout.print("Executing WokeLang code...\n", .{});
    try stdout.print("---\n", .{});

    interp.exec(woke_code) catch |err| {
        try stdout.print("Error: {}\n", .{err});
        return;
    };

    try stdout.print("---\n", .{});
    try stdout.print("Done!\n", .{});
}
