const std = @import("std");
const Scanner = @import("deps/zig-wayland/build.zig").Scanner;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const xkbcommon = b.createModule(
        .{ .source_file = .{ .path = "deps/zig-xkbcommon/src/xkbcommon.zig" } },
    );

    const opts = .{ .target = target, .optimize = optimize };
    const giza = b.dependency("giza", opts);
    const cairo = giza.module("cairo");

    const scanner = Scanner.create(b, .{});
    const wayland = b.createModule(.{ .source_file = scanner.result });
    scanner.addCustomProtocol("protocols/wlr-layer-shell-unstable-v1.xml");
    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");
    scanner.addSystemProtocol("unstable/xdg-output/xdg-output-unstable-v1.xml");

    scanner.generate("wl_compositor", 1);
    scanner.generate("wl_shm", 1);
    scanner.generate("wl_output", 4);
    scanner.generate("wl_seat", 5);
    scanner.generate("zwlr_layer_shell_v1", 4);
    scanner.generate("zxdg_output_manager_v1", 3);

    const exe = b.addExecutable(.{
        .name = "seto",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.addModule("wayland", wayland);
    exe.addModule("cairo", cairo);
    exe.addModule("xkbcommon", xkbcommon);
    exe.linkSystemLibrary("wayland-client");
    exe.linkSystemLibrary("cairo");
    exe.linkSystemLibrary("xkbcommon");

    if (optimize == .Debug) {
        exe.linkSystemLibrary("fontconfig");
    }

    exe.linkLibC();

    // TODO: remove when https://github.com/ziglang/zig/issues/131 is implemented
    scanner.addCSource(exe);

    b.installArtifact(exe);
}
