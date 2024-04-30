const std = @import("std");
const mem = std.mem;
const os = std.os;

const Surface = @import("surface.zig").Surface;
const layerSurfaceListener = @import("surface.zig").layerSurfaceListener;
const OutputInfo = @import("surface.zig").OutputInfo;
const xdgOutputListener = @import("surface.zig").xdgOutputListener;

const Seat = @import("seat.zig").Seat;
const keyboardListener = @import("seat.zig").keyboardListener;
const seatListener = @import("seat.zig").seatListener;

const xkb = @import("xkbcommon");

const wayland = @import("wayland");
const wl = wayland.client.wl;
const zwlr = wayland.client.zwlr;
const zxdg = wayland.client.zxdg;

const EventInterfaces = enum {
    wl_shm,
    wl_compositor,
    zwlr_layer_shell_v1,
    wl_output,
    wl_seat,
    zxdg_output_manager_v1,
};

pub const Seto = struct {
    shm: ?*wl.Shm = null,
    compositor: ?*wl.Compositor = null,
    layer_shell: ?*zwlr.LayerShellV1 = null,
    output_manager: ?*zxdg.OutputManagerV1 = null,
    seat: Seat,
    outputs: std.ArrayList(Surface),
    alloc: mem.Allocator,

    fn new() Seto {
        const alloc = std.heap.c_allocator;
        return Seto{
            .seat = Seat.new(),
            .outputs = std.ArrayList(Surface).init(alloc),
            .alloc = alloc,
        };
    }

    fn get_dimensions(self: *Seto) void {
        _ = self;
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

pub fn main() !void {
    const display = try wl.Display.connect(null);
    const registry = try display.getRegistry();

    var seto = Seto.new();
    defer seto.destroy();

    registry.setListener(*Seto, registryListener, &seto);

    while (!seto.seat.exit) {
        if (display.roundtrip() != .SUCCESS) return error.RoundtripFailed;
        if (display.dispatch() != .SUCCESS) return error.DispatchFailed;
        for (seto.outputs.items) |*surface| {
            if (surface.is_configured()) {
                const width = surface.dimensions[0];
                const height = surface.dimensions[1];
                const stride = width * 4;
                const size = stride * height;

                const fd = try os.memfd_create("seto", 0);
                defer os.close(fd);
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
                    seto.shm = registry.bind(global.name, wl.Shm, wl.Shm.generated_version) catch return;
                },
                .wl_compositor => {
                    seto.compositor = registry.bind(global.name, wl.Compositor, wl.Compositor.generated_version) catch return;
                },
                .zwlr_layer_shell_v1 => {
                    seto.layer_shell = registry.bind(global.name, zwlr.LayerShellV1, zwlr.LayerShellV1.generated_version) catch return;
                },
                .wl_output => {
                    var bound = registry.bind(
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
                    layer_surface.setKeyboardInteractivity(.exclusive);
                    surface.commit();

                    const a = seto.output_manager.?.getXdgOutput(bound) catch return;
                    var output_info = OutputInfo{ .alloc = seto.alloc, .wl = bound };

                    a.setListener(*OutputInfo, xdgOutputListener, &output_info);

                    const output = Surface.new(surface, layer_surface, seto.alloc, &output_info);
                    seto.outputs.append(output) catch return;
                },
                .wl_seat => {
                    const wl_seat = registry.bind(global.name, wl.Seat, wl.Seat.generated_version) catch return;
                    seto.seat.wl_seat = wl_seat;
                    wl_seat.setListener(*Seat, seatListener, &seto.seat);
                },
                .zxdg_output_manager_v1 => {
                    seto.output_manager = registry.bind(
                        global.name,
                        zxdg.OutputManagerV1,
                        zxdg.OutputManagerV1.generated_version,
                    ) catch return;
                },
            }
        },
        .global_remove => {},
    }
}
