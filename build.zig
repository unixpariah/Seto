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
    const cairo = b.createModule(
        .{ .source_file = .{ .path = "deps/zig-cairo/src/cairo.zig" } },
    );

    scanner.addCustomProtocol("protocols/wlr-layer-shell-unstable-v1.xml");
    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");

    scanner.generate("wl_compositor", 1);
    scanner.generate("wl_shm", 1);
    scanner.generate("zwlr_layer_shell_v1", 4);
    scanner.generate("wl_output", 4);
    scanner.generate("wl_seat", 5);

    const seto = b.addExecutable(.{
        .name = "seto",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    seto.addModule("wayland", wayland);
    seto.addModule("cairo", cairo);
    seto.addModule("xkbcommon", xkbcommon);
    seto.linkSystemLibrary("wayland-client");
    seto.linkSystemLibrary("cairo");
    seto.linkSystemLibrary("xkbcommon");

    seto.linkLibC();

    // TODO: remove when https://github.com/ziglang/zig/issues/131 is implemented
    scanner.addCSource(seto);

    b.installArtifact(seto);
}
