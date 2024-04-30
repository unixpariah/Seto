const std = @import("std");
const Scanner = @import("deps/zig-wayland/build.zig").Scanner;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const scanner = Scanner.create(b, .{});

    const wayland = b.createModule(.{ .source_file = scanner.result });
    const xkbcommon = b.createModule(
        .{ .source_file = .{ .path = "deps/zig-xkbcommon/src/xkbcommon.zig" } },
    );

    const opts = .{ .target = target, .optimize = optimize };
    const dep = b.dependency("giza", opts);
    const cairo = dep.module("cairo");

    scanner.addCustomProtocol("protocols/wlr-layer-shell-unstable-v1.xml");
    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");

    scanner.generate("wl_compositor", 1);
    scanner.generate("wl_shm", 1);
    scanner.generate("zwlr_layer_shell_v1", 4);
    scanner.generate("wl_output", 4);
    scanner.generate("wl_seat", 5);

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

    exe.linkLibC();

    // TODO: remove when https://github.com/ziglang/zig/issues/131 is implemented
    scanner.addCSource(exe);

    b.installArtifact(exe);
}
