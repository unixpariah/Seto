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
    zxdg_output_manager_v1,
};

const Context = struct {
    shm: ?*wl.Shm,
    compositor: ?*wl.Compositor,
    layer_shell: ?*zwlr.LayerShellV1,
    outputs: std.ArrayList(surf.Surface),
    alloc: mem.Allocator,

    fn new(alloc: mem.Allocator) Context {
        return Context{
            .shm = null,
            .compositor = null,
            .layer_shell = null,
            .outputs = std.ArrayList(surf.Surface).init(alloc),
            .alloc = alloc,
        };
    }

    fn destroy(self: *Context) void {
        self.compositor.?.destroy();
    }
};

pub fn main() anyerror!void {
    var allocator = std.heap.page_allocator;

    const display = try wl.Display.connect(null);
    const registry = try display.getRegistry();

    var context = Context.new(allocator);
    defer context.destroy();

    registry.setListener(*Context, registryListener, &context);

    var running = true;

    while (running) {
        if (display.dispatch() != .SUCCESS) return error.DispatchFailed;
        for (context.outputs.items) |*elem| {
            if (elem.size[0] > 0 and elem.size[1] > 0) {
                const width = elem.size[0];
                const height = elem.size[1];
                const stride = width * 4;
                const size: usize = @intCast(stride * height);

                const fd = try os.memfd_create("sip", 0);
                try os.ftruncate(fd, size);

                const shm = context.shm orelse return error.NoWlShm;
                const pool = try shm.createPool(fd, @intCast(size));
                defer pool.destroy();

                try elem.draw(pool, fd);
            } else {
                elem.layer_surface.setListener(*[2]c_int, layerSurfaceListener, &elem.size);
            }
        }
    }
}

fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, context: *Context) void {
    switch (event) {
        .global => |global| {
            const events = std.meta.stringToEnum(EventInterfaces, std.mem.span(global.interface)) orelse return;
            switch (events) {
                .wl_shm => {
                    context.shm = registry.bind(global.name, wl.Shm, 1) catch return;
                },
                .wl_compositor => {
                    context.compositor = registry.bind(global.name, wl.Compositor, 1) catch return;
                },
                .zwlr_layer_shell_v1 => {
                    context.layer_shell = registry.bind(global.name, zwlr.LayerShellV1, zwlr.LayerShellV1.generated_version) catch return;
                },
                .wl_output => {
                    const bound = registry.bind(
                        global.name,
                        wl.Output,
                        wl.Output.generated_version,
                    ) catch return;

                    const compositor = context.compositor orelse return;

                    const surface = compositor.createSurface() catch return;

                    const layer_surface = context.layer_shell.?.getLayerSurface(surface, bound, .overlay, "sip") catch return;
                    layer_surface.setAnchor(.{
                        .top = true,
                        .right = true,
                        .bottom = true,
                        .left = true,
                    });
                    layer_surface.setExclusiveZone(-1);
                    surface.commit();

                    var output = Surface{ .surface = surface, .layer_surface = layer_surface, .size = undefined };

                    context.outputs.append(output) catch return;
                },
                .zxdg_output_manager_v1 => {},
            }
        },
        .global_remove => {},
    }
}

fn layerSurfaceListener(lsurf: *zwlr.LayerSurfaceV1, ev: zwlr.LayerSurfaceV1.Event, winsize: *[2]c_int) void {
    switch (ev) {
        .configure => |configure| {
            winsize.* = .{ @intCast(configure.width), @intCast(configure.height) };
            lsurf.setSize(configure.width, configure.height);
            lsurf.ackConfigure(configure.serial);
        },
        .closed => {},
    }
}
