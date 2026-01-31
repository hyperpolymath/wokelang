// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build shared library
    const lib = b.addSharedLibrary(.{
        .name = "wokelang",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link with Rust implementation
    lib.linkLibC();
    lib.addLibraryPath(b.path("../../target/release"));
    lib.linkSystemLibrary("wokelang");

    b.installArtifact(lib);

    // Build tests
    const tests = b.addTest(.{
        .root_source_file = b.path("test/integration_test.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests.linkLibrary(lib);

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run integration tests");
    test_step.dependOn(&run_tests.step);

    // Build example
    const example = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path("../../zig/example.zig"),
        .target = target,
        .optimize = optimize,
    });
    example.linkLibrary(lib);

    const run_example = b.addRunArtifact(example);
    const example_step = b.step("example", "Run example");
    example_step.dependOn(&run_example.step);
}
