const std = @import("std");
const mem = std.mem;
const os = std.os;
const surf = @import("surface.zig");

const wayland = @import("wayland");
const wl = wayland.client.wl;
const zwlr = wayland.client.zwlr;
const Surface = surf.Surface;

const EventInterfaces = enum {
    wl_shm,
    wl_compositor,
    zwlr_layer_shell_v1,
    wl_output,
};

const Seto = struct {
    shm: ?*wl.Shm,
    compositor: ?*wl.Compositor,
    layer_shell: ?*zwlr.LayerShellV1,
    outputs: std.ArrayList(surf.Surface),
    alloc: mem.Allocator,

    fn new() Seto {
        const alloc = std.heap.page_allocator;
        return Seto{
            .shm = null,
            .compositor = null,
            .layer_shell = null,
            .outputs = std.ArrayList(surf.Surface).init(alloc),
            .alloc = alloc,
        };
    }

    fn destroy(self: *Seto) void {
        self.compositor.?.destroy();
        self.layer_shell.?.destroy();
        self.shm.?.destroy();
        for (self.outputs.items) |*surface| {
            surface.destroy();
        }
    }
};

pub fn main() anyerror!void {
    const display = try wl.Display.connect(null);
    const registry = try display.getRegistry();

    var seto = Seto.new();
    defer seto.destroy();

    registry.setListener(*Seto, registryListener, &seto);

    while (true) {
        if (display.dispatch() != .SUCCESS) return error.DispatchFailed;
        for (seto.outputs.items) |*surface| {
            const width = surface.dimensions[0];
            const height = surface.dimensions[1];
            if (surface.is_configured()) {
                const stride = width * 4;
                const size = stride * height;

                const fd = try os.memfd_create("seto", 0);
                try os.ftruncate(fd, @intCast(size));

                const shm = seto.shm orelse return error.NoWlShm;
                const pool = try shm.createPool(fd, size);
                defer pool.destroy();

                try surface.draw(pool, fd);
            }
        }
    }
}

fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, seto: *Seto) void {
    switch (event) {
        .global => |global| {
            const events = std.meta.stringToEnum(EventInterfaces, std.mem.span(global.interface)) orelse return;
            switch (events) {
                .wl_shm => {
                    seto.shm = registry.bind(global.name, wl.Shm, 1) catch return;
                },
                .wl_compositor => {
                    seto.compositor = registry.bind(global.name, wl.Compositor, 1) catch return;
                },
                .zwlr_layer_shell_v1 => {
                    seto.layer_shell = registry.bind(global.name, zwlr.LayerShellV1, zwlr.LayerShellV1.generated_version) catch return;
                },
                .wl_output => {
                    const bound = registry.bind(
                        global.name,
                        wl.Output,
                        wl.Output.generated_version,
                    ) catch return;

                    const compositor = seto.compositor orelse return;
                    const surface = compositor.createSurface() catch return;

                    const layer_surface = seto.layer_shell.?.getLayerSurface(surface, bound, .overlay, "seto") catch return;
                    layer_surface.setListener(*Seto, layerSurfaceListener, seto);
                    layer_surface.setAnchor(.{
                        .top = true,
                        .right = true,
                        .bottom = true,
                        .left = true,
                    });
                    layer_surface.setExclusiveZone(-1);
                    surface.commit();

                    const output = Surface.new(surface, layer_surface, seto.alloc);

                    seto.outputs.append(output) catch return;
                },
            }
        },
        .global_remove => {},
    }
}

fn layerSurfaceListener(lsurf: *zwlr.LayerSurfaceV1, ev: zwlr.LayerSurfaceV1.Event, seto: *Seto) void {
    switch (ev) {
        .configure => |configure| {
            for (seto.outputs.items) |*surface| {
                if (surface.layer_surface == lsurf) {
                    surface.dimensions = .{ @intCast(configure.width), @intCast(configure.height) };
                    surface.layer_surface.setSize(configure.width, configure.height);
                    surface.layer_surface.ackConfigure(configure.serial);
                }
            }
        },
        .closed => {},
    }
}
