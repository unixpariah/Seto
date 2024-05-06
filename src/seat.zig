const std = @import("std");
const os = std.os;

const xkb = @import("xkbcommon");
const wayland = @import("wayland");
const wl = wayland.client.wl;

const Seto = @import("main.zig").Seto;

const Repeat = struct {
    rate: ?i32 = null,
    delay: ?i32 = null,
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
            .xkb_context = xkb.Context.new(.no_flags) orelse std.debug.panic("", .{}),
            .buffer = std.ArrayList([64]u8).init(alloc),
            .alloc = alloc,
        };
    }

    pub fn repeatKey(self: *Self) bool {
        var timer = self.repeat.timer orelse return false;
        var delay = self.repeat.delay orelse return false;
        return timer.read() / std.time.ns_per_ms > delay;
    }

    pub fn destroy(self: *Self) void {
        if (self.wl_seat) |wl_seat| wl_seat.release();
        if (self.wl_keyboard) |wl_keyboard| wl_keyboard.destroy();
        if (self.xkb_state) |xkb_state| xkb_state.unref();
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
            defer os.close(ev.fd);

            if (ev.format != .xkb_v1) return;

            const keymap_string = os.mmap(null, ev.size, os.PROT.READ, os.MAP.PRIVATE, ev.fd, 0) catch return;
            defer os.munmap(keymap_string);

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
            if (ev.state == .released) {
                seto.seat.repeat.timer = null;
                seto.seat.repeat.key = null;
                seto.redraw = false;
            }
            if (ev.state != .pressed) return;

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
        .repeat_info => |repeat_key| {
            seto.seat.repeat.rate = repeat_key.rate;
            seto.seat.repeat.delay = repeat_key.delay;
        },
    }
}

pub fn handleKey(self: *Seto) void {
    const key = self.seat.repeat.key orelse return;
    self.redraw = true;

    const ctrl_active = self.seat.xkb_state.?.modNameIsActive(
        xkb.names.mod.ctrl,
        @enumFromInt(xkb.State.Component.mods_depressed | xkb.State.Component.mods_latched),
    ) == 1;
    switch (key) {
        xkb.Keysym.m => {
            if (self.grid.offset[0] >= self.grid.size[0]) self.grid.offset[0] -= self.grid.size[0];
            self.grid.offset[0] += 5;
            return;
        },
        xkb.Keysym.n => {
            if (self.grid.offset[1] < 5) self.grid.offset[1] = self.grid.size[1];
            self.grid.offset[1] -= 5;
            return;
        },
        xkb.Keysym.x => {
            if (self.grid.offset[1] >= self.grid.size[1]) self.grid.offset[1] -= self.grid.size[1];
            self.grid.offset[1] += 5;
            return;
        },
        xkb.Keysym.z => {
            if (self.grid.offset[0] < 5) self.grid.offset[0] = self.grid.size[0];
            self.grid.offset[0] -= 5;
            return;
        },
        xkb.Keysym.M => {
            self.grid.size[0] += 5;
            return;
        },
        xkb.Keysym.N => {
            if (self.grid.size[1] >= 5) self.grid.size[1] -= 5;
            return;
        },
        xkb.Keysym.X => {
            self.grid.size[1] += 5;
            return;
        },
        xkb.Keysym.Z => {
            if (self.grid.size[0] >= 5) self.grid.size[0] -= 5;
            return;
        },
        xkb.Keysym.q => self.exit = true,
        xkb.Keysym.c => {
            if (ctrl_active) {
                self.exit = true;
                return;
            }
        },
        xkb.Keysym.BackSpace => {
            _ = self.seat.buffer.popOrNull();
            return;
        },
        xkb.Keysym.Shift_R | xkb.Keysym.Shift_R => return,
        else => {},
    }

    if (self.seat.buffer.items.len < self.depth) {
        var buffer: [64]u8 = undefined;
        const keynum: xkb.Keysym = @enumFromInt(key);
        _ = keynum.getName(&buffer, 64);
        self.seat.buffer.append(buffer) catch return;
    }
}
