const std = @import("std");
const posix = std.posix;

const xkb = @import("xkbcommon");
const wayland = @import("wayland");
const wl = wayland.client.wl;

const Mode = @import("main.zig").Mode;
const Seto = @import("main.zig").Seto;

const Repeat = struct {
    delay: ?i32 = null,
    rate: ?i32 = null,
    key: ?u32 = null,
    timer: ?std.time.Timer = null,
};

pub const Seat = struct {
    wl_seat: ?*wl.Seat = null,
    wl_keyboard: ?*wl.Keyboard = null,
    xkb_state: ?*xkb.State = null,
    xkb_context: *xkb.Context,
    alloc: std.mem.Allocator,
    repeat: Repeat = Repeat{},
    buffer: std.ArrayList([64]u8),

    const Self = @This();

    pub fn new(alloc: std.mem.Allocator) Self {
        return .{
            .xkb_context = xkb.Context.new(.no_flags) orelse @panic(""),
            .buffer = std.ArrayList([64]u8).init(alloc),
            .alloc = alloc,
        };
    }

    pub fn repeatKey(self: *Self) bool {
        var timer = self.repeat.timer orelse return false;
        const delay = self.repeat.delay orelse return false;
        return timer.read() / std.time.ns_per_ms > delay;
    }

    pub fn destroy(self: *Self) void {
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
            defer posix.close(ev.fd);

            if (ev.format != .xkb_v1) return;

            const keymap_string = posix.mmap(null, ev.size, posix.PROT.READ, posix.MAP{ .TYPE = .PRIVATE }, ev.fd, 0) catch return;
            defer posix.munmap(keymap_string);

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
                    seto.seat.repeat.timer = null;
                    seto.seat.repeat.key = null;
                },
                .pressed => {
                    seto.seat.repeat.timer = std.time.Timer.start() catch return;

                    const xkb_state = seto.seat.xkb_state orelse return;

                    // The wayland protocol gives us an input event code. To convert this to an xkb
                    // keycode we must add 8.
                    const keycode = ev.key + 8;

                    const keysym = xkb_state.keyGetOneSym(keycode);
                    if (keysym == .NoSymbol) return;

                    seto.seat.repeat.key = @intFromEnum(keysym);
                    handleKey(seto);
                },
                _ => {},
            }
        },
        .repeat_info => |repeat_key| {
            seto.seat.repeat.delay = repeat_key.delay;
            seto.seat.repeat.rate = repeat_key.delay;
        },
    }
}

fn moveSelection(seto: *Seto, value: [2]i32) void {
    if (seto.state.mode == .Single) return;
    if (seto.state.mode.Region) |*position| {
        const info: [2]i32 = .{ seto.outputs.items[0].output_info.x, seto.outputs.items[0].output_info.y };
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

    {
        var buffer: [64]u8 = undefined;
        const keysym: xkb.Keysym = @enumFromInt(key);
        _ = keysym.toUTF8(&buffer, 64);
        if (self.config.keys.bindings.get(buffer[0])) |function| {
            switch (function) {
                .move => |value| grid.move(value),
                .resize => |value| grid.resize(value),
                .remove => _ = self.seat.buffer.popOrNull(),
                .cancel_selection => if (self.state.mode == Mode.Region) {
                    self.state.mode = Mode{ .Region = null };
                },
                .move_selection => |value| moveSelection(self, value),
                .border_select => self.state.border_mode = !self.state.border_mode,
                .quit => self.state.exit = true,
            }

            if ((function == .move or function == .resize) and !self.state.border_mode) {
                self.tree.?.updateCoordinates(
                    &self.config.grid,
                    self.state.border_mode,
                    &self.outputs.items,
                    &self.seat.buffer,
                );
                return;
            }

            if (function == .border_select or function == .move_selection or function == .cancel_selection) return;
        }

        if (buffer[0] == 'c' and ctrl_active) self.state.exit = true;
    }

    var buffer: [64]u8 = undefined;
    const keynum: xkb.Keysym = @enumFromInt(key);
    _ = keynum.getName(&buffer, 64);
    self.seat.buffer.append(buffer) catch return;
}
