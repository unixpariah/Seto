const std = @import("std");
const mem = std.mem;
const os = std.os;
const Surface = @import("surface.zig").Surface;
const xkb = @import("xkbcommon");

const wayland = @import("wayland");
const wl = wayland.client.wl;
const zwlr = wayland.client.zwlr;

const EventInterfaces = enum {
    wl_shm,
    wl_compositor,
    zwlr_layer_shell_v1,
    wl_output,
    wl_seat,
};

const Seto = struct {
    shm: ?*wl.Shm,
    compositor: ?*wl.Compositor,
    layer_shell: ?*zwlr.LayerShellV1,
    wl_seat: ?*wl.Seat,
    wl_keyboard: ?*wl.Keyboard,
    xkb_state: ?*xkb.State,
    xkb_context: *xkb.Context,
    outputs: std.ArrayList(Surface),
    alloc: mem.Allocator,
    exit: bool,

    fn new() Seto {
        const alloc = std.heap.c_allocator;
        return Seto{
            .shm = null,
            .compositor = null,
            .layer_shell = null,
            .wl_seat = null,
            .wl_keyboard = null,
            .xkb_state = null,
            .xkb_context = xkb.Context.new(.no_flags) orelse std.debug.panic("", .{}),
            .outputs = std.ArrayList(Surface).init(alloc),
            .alloc = alloc,
            .exit = false,
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

pub fn main() !void {
    const display = try wl.Display.connect(null);
    const registry = try display.getRegistry();

    var seto = Seto.new();
    defer seto.destroy();

    registry.setListener(*Seto, registryListener, &seto);

    while (!seto.exit) {
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
                    layer_surface.setKeyboardInteractivity(.exclusive);
                    surface.commit();

                    const output = Surface.new(surface, layer_surface, seto.alloc);

                    seto.outputs.append(output) catch return;
                },
                .wl_seat => {
                    const wl_seat = registry.bind(global.name, wl.Seat, wl.Seat.generated_version) catch return;
                    seto.wl_seat = wl_seat;
                    wl_seat.setListener(*Seto, seatListener, seto);
                },
            }
        },
        .global_remove => {},
    }
}

fn seatListener(wl_seat: *wl.Seat, event: wl.Seat.Event, seto: *Seto) void {
    switch (event) {
        .name => {},
        .capabilities => |ev| {
            if (ev.capabilities.keyboard and seto.wl_keyboard == null) {
                const wl_keyboard = wl_seat.getKeyboard() catch return;
                seto.wl_keyboard = wl_keyboard;
                wl_keyboard.setListener(*Seto, keyboardListener, seto);
            } else if (!ev.capabilities.keyboard and seto.wl_keyboard != null) {
                seto.wl_keyboard.?.release();
                seto.wl_keyboard = null;
            }
        },
    }
}

fn keyboardListener(_: *wl.Keyboard, event: wl.Keyboard.Event, seto: *Seto) void {
    switch (event) {
        .enter => {},
        .leave => {},
        .keymap => |ev| {
            defer os.close(ev.fd);

            if (ev.format != .xkb_v1) return;

            const keymap_string = os.mmap(null, ev.size, os.PROT.READ, os.MAP.PRIVATE, ev.fd, 0) catch return;
            defer os.munmap(keymap_string);

            const keymap = xkb.Keymap.newFromBuffer(
                seto.xkb_context,
                keymap_string.ptr,
                keymap_string.len - 1,
                .text_v1,
                .no_flags,
            ) orelse return;
            defer keymap.unref();

            const state = xkb.State.new(keymap) orelse return;
            defer state.unref();

            if (seto.xkb_state) |s| s.unref();
            seto.xkb_state = state.ref();
        },
        .modifiers => |ev| {
            if (seto.xkb_state) |xkb_state| {
                _ = xkb_state.updateMask(
                    ev.mods_depressed,
                    ev.mods_latched,
                    ev.mods_locked,
                    0,
                    0,
                    ev.group,
                );
            }
        },
        .key => |ev| {
            if (ev.state != .pressed) return;

            const xkb_state = seto.xkb_state orelse return;

            // The wayland protocol gives us an input event code. To convert this to an xkb
            // keycode we must add 8.
            const keycode = ev.key + 8;

            const keysym = xkb_state.keyGetOneSym(keycode);
            if (keysym == .NoSymbol) return;

            switch (@intFromEnum(keysym)) {
                xkb.Keysym.q => {
                    seto.exit = true;
                    return;
                },
                xkb.Keysym.c => {
                    const ctrl_active = xkb_state.modNameIsActive(
                        xkb.names.mod.ctrl,
                        @enumFromInt(xkb.State.Component.mods_depressed | xkb.State.Component.mods_latched),
                    ) == 1;

                    if (ctrl_active) {
                        seto.exit = true;
                    }
                },
                xkb.Keysym.Control_L | xkb.Keysym.Control_R => {},
                else => {},
            }
        },
        .repeat_info => {},
    }
}

fn layerSurfaceListener(lsurf: *zwlr.LayerSurfaceV1, event: zwlr.LayerSurfaceV1.Event, seto: *Seto) void {
    switch (event) {
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
