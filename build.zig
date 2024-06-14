const std = @import("std");
const Scanner = @import("zig-wayland").Scanner;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const opts = .{ .target = target, .optimize = optimize };

    const scanner = Scanner.create(b, .{});
    const wayland = b.createModule(.{ .root_source_file = scanner.result });
    scanner.addCustomProtocol("protocols/wlr-layer-shell-unstable-v1.xml");
    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");
    scanner.addSystemProtocol("unstable/xdg-output/xdg-output-unstable-v1.xml");
    scanner.generate("wl_compositor", 1);
    scanner.generate("wl_shm", 1);
    scanner.generate("wl_output", 4);
    scanner.generate("wl_seat", 5);
    scanner.generate("zwlr_layer_shell_v1", 4);
    scanner.generate("zxdg_output_manager_v1", 3);

    const cairo = b.dependency("giza", opts).module("cairo");
    const pango = b.dependency("giza", opts).module("pango");
    const pangocairo = b.dependency("giza", opts).module("pangocairo");

    const xkbcommon = b.dependency("zig-xkbcommon", .{}).module("xkbcommon");

    const ziglua = b.dependency("ziglua", opts).module("ziglua");

    const exe = b.addExecutable(.{
        .name = "seto",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();

    exe.root_module.addImport("wayland", wayland);
    exe.root_module.addImport("cairo", cairo);
    exe.root_module.addImport("pango", pango);
    exe.root_module.addImport("pangocairo", pangocairo);
    exe.root_module.addImport("xkbcommon", xkbcommon);
    exe.root_module.addImport("ziglua", ziglua);
    exe.linkSystemLibrary("wayland-client");
    exe.linkSystemLibrary("cairo");
    exe.linkSystemLibrary("pango");
    exe.linkSystemLibrary("pangocairo");
    exe.linkSystemLibrary("xkbcommon");
    exe.linkSystemLibrary("egl");
    exe.linkSystemLibrary("gl");
    exe.linkSystemLibrary("wayland-egl");

    // TODO: remove when https://github.com/ziglang/zig/issues/131 is implemented
    scanner.addCSource(exe);

    b.installArtifact(exe);

    const unit_tests_step = b.step("test", "Run all tests");
    unit_tests_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_source_file = b.path("src/config.zig") })).step);
    unit_tests_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_source_file = b.path("src/tree.zig") })).step);
    unit_tests_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_source_file = b.path("tests/integration.zig") })).step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run client");
    run_step.dependOn(&run_cmd.step);
}
