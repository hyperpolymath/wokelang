const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Example executable using WokeLang FFI
    const exe = b.addExecutable(.{
        .name = "wokelang-zig-example",
        .root_source_file = b.path("example.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link against the WokeLang library
    exe.addLibraryPath(.{ .cwd_relative = "../target/release" });
    exe.linkSystemLibrary("wokelang");
    exe.linkLibC();

    // Add include path for header
    exe.addIncludePath(.{ .cwd_relative = "../include" });

    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("wokelang.zig"),
        .target = target,
        .optimize = optimize,
    });

    unit_tests.addLibraryPath(.{ .cwd_relative = "../target/release" });
    unit_tests.linkSystemLibrary("wokelang");
    unit_tests.linkLibC();

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
