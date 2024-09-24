const std = @import("std");

const xkb = @import("xkbcommon");
const wayland = @import("wayland");
const wl = wayland.client.wl;

const Mode = @import("main.zig").Mode;
const Seto = @import("main.zig").Seto;
const Timer = @import("Timer.zig");

const Repeat = struct {
    delay: ?f32 = null,
    rate: ?f32 = null,
    key: ?u32 = null,
    timer: Timer,

    const Self = @This();
};

pub const Seat = struct {
    wl_seat: ?*wl.Seat = null,
    wl_keyboard: ?*wl.Keyboard = null,
    xkb_state: ?*xkb.State = null,
    xkb_context: *xkb.Context,
    alloc: std.mem.Allocator,
    repeat: Repeat,
    buffer: std.ArrayList(u32),

    const Self = @This();

    pub fn init(alloc: std.mem.Allocator) !Self {
        return .{
            .xkb_context = xkb.Context.new(.no_flags) orelse return error.XkbError,
            .buffer = std.ArrayList(u32).init(alloc),
            .alloc = alloc,
            .repeat = Repeat{ .timer = try Timer.init() },
        };
    }

    pub fn deinit(self: *Self) void {
        self.wl_seat.?.destroy();
        self.wl_keyboard.?.destroy();
        self.xkb_state.?.unref();
        self.buffer.deinit();
        self.xkb_context.unref();
    }
};

pub fn seatListener(wl_seat: *wl.Seat, event: wl.Seat.Event, seto: *Seto) void {
    switch (event) {
        .name => {},
        .capabilities => |ev| {
            if (ev.capabilities.keyboard and seto.seat.wl_keyboard == null) {
                const wl_keyboard = wl_seat.getKeyboard() catch return;
                seto.seat.wl_keyboard = wl_keyboard;
                wl_keyboard.setListener(*Seto, keyboardListener, seto);
            } else if (!ev.capabilities.keyboard and seto.seat.wl_keyboard != null) {
                seto.seat.wl_keyboard.?.release();
                seto.seat.wl_keyboard = null;
            }
        },
    }
}

pub fn keyboardListener(_: *wl.Keyboard, event: wl.Keyboard.Event, seto: *Seto) void {
    switch (event) {
        .enter => {},
        .leave => {},
        .keymap => |ev| {
            defer std.posix.close(ev.fd);

            if (ev.format != .xkb_v1) return;

            const keymap_string = std.posix.mmap(null, ev.size, std.posix.PROT.READ, std.posix.MAP{ .TYPE = .PRIVATE }, ev.fd, 0) catch return;
            defer std.posix.munmap(keymap_string);

            const keymap = xkb.Keymap.newFromBuffer(
                seto.seat.xkb_context,
                keymap_string.ptr,
                keymap_string.len - 1,
                .text_v1,
                .no_flags,
            ) orelse return;
            defer keymap.unref();

            const state = xkb.State.new(keymap) orelse return;
            defer state.unref();

            if (seto.seat.xkb_state) |s| s.unref();
            seto.seat.xkb_state = state.ref();
        },
        .modifiers => |ev| {
            if (seto.seat.xkb_state) |xkb_state| {
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
            switch (ev.state) {
                .released => {
                    const xkb_state = seto.seat.xkb_state orelse return;

                    // The wayland protocol gives us an input event code. To convert this to an xkb
                    // keycode we must add 8.
                    const keycode = ev.key + 8;

                    const keysym = xkb_state.keyGetOneSym(keycode);
                    if (keysym == .NoSymbol) return;

                    if (keysym.toUTF32() != seto.seat.repeat.key) return;

                    seto.seat.repeat.timer.stop() catch return;
                },
                .pressed => {
                    const xkb_state = seto.seat.xkb_state orelse return;

                    // The wayland protocol gives us an input event code. To convert this to an xkb
                    // keycode we must add 8.
                    const keycode = ev.key + 8;

                    const keysym = xkb_state.keyGetOneSym(keycode);
                    if (keysym == .NoSymbol) return;

                    if (xkb_state.getKeymap().keyRepeats(keycode) == 1) {
                        seto.seat.repeat.timer.start(
                            seto.seat.repeat.delay.?,
                            1000 / seto.seat.repeat.rate.?,
                        ) catch return;
                    } else {
                        seto.seat.repeat.timer.stop() catch return;
                    }

                    seto.seat.repeat.key = @intFromEnum(keysym);
                    handleKey(seto);
                    seto.render() catch return;
                },
                _ => {},
            }
        },
        .repeat_info => |repeat_key| {
            seto.seat.repeat.delay = @floatFromInt(repeat_key.delay);
            seto.seat.repeat.rate = 60; //repeat_key.rate;
        },
    }
}

fn moveSelection(seto: *Seto, value: [2]f32) void {
    if (seto.state.mode == .Single) return;
    if (seto.state.mode.Region) |*position| {
        const info: [2]f32 = .{ seto.outputs.items[0].info.x, seto.outputs.items[0].info.y };
        for (position, 0..) |*pos, i| {
            pos.* += value[i];

            if (pos.* < info[i]) {
                pos.* = info[i];
            } else if (pos.* > info[i] + seto.total_dimensions[i]) {
                pos.* = info[i] + seto.total_dimensions[i];
            }
        }
    }
}

pub fn handleKey(self: *Seto) void {
    const key = self.seat.repeat.key orelse return;
    const grid = &self.config.grid;

    const ctrl_active = self.seat.xkb_state.?.modNameIsActive(
        xkb.names.mod.ctrl,
        @enumFromInt(xkb.State.Component.mods_depressed | xkb.State.Component.mods_latched),
    ) == 1;

    const keysym: xkb.Keysym = @enumFromInt(key);
    const utf32_keysym = keysym.toUTF32();

    if (key == xkb.Keysym.BackSpace) {
        _ = self.seat.buffer.popOrNull();
    } else if (utf32_keysym == 'c' and ctrl_active) {
        self.state.exit = true;
    } else if (self.config.keys.bindings.get(@intCast(utf32_keysym))) |function| {
        switch (function) {
            .move => |value| grid.move(value),
            .resize => |value| grid.resize(value),
            .cancel_selection => if (self.state.mode == Mode.Region) {
                self.state.mode = Mode{ .Region = null };
            },
            .move_selection => |value| moveSelection(self, value),
            .border_mode => self.state.border_mode = !self.state.border_mode,
            .quit => self.state.exit = true,
        }

        // self.tree.?.updateCoordinates(
        //     &self.config,
        //     self.state.border_mode,
        //     &self.outputs.items,
        //     &self.seat.buffer,
        // );
    } else {
        self.seat.buffer.append(utf32_keysym) catch @panic("OOM");

        self.printToStdout() catch |err| {
            switch (err) {
                error.KeyNotFound => {
                    _ = self.seat.buffer.popOrNull();
                    return;
                },
                else => {},
            }
        };
    }
}
