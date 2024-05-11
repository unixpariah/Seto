const std = @import("std");
const posix = std.posix;
const Grid = @import("config.zig").Grid;

const xkb = @import("xkbcommon");
const wayland = @import("wayland");
const wl = wayland.client.wl;

const Seto = @import("main.zig").Seto;

const Repeat = struct {
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
        const delay = self.repeat.delay orelse return false;
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
            seto.seat.repeat.delay = repeat_key.delay;
        },
    }
}

fn moveX(grid: *Grid, value: i32) void {
    if (grid.offset[0] >= grid.size[0]) grid.offset[0] -= grid.size[0];
    if (grid.offset[0] < 5) grid.offset[0] = grid.size[0];
    grid.offset[0] += value;
}

fn moveY(grid: *Grid, value: i32) void {
    if (grid.offset[1] >= grid.size[1]) grid.offset[1] -= grid.size[1];
    if (grid.offset[1] < 5) grid.offset[1] = grid.size[1];
    grid.offset[1] += value;
}

fn resizeX(grid: *Grid, value: i32) void {
    if (grid.size[0] + value > 0) grid.size[0] += value;
}

fn resizeY(grid: *Grid, value: i32) void {
    if (grid.size[1] + value > 0) grid.size[1] += value;
}

pub fn handleKey(self: *Seto) void {
    const key = self.seat.repeat.key orelse return;
    const grid = &self.config.grid;
    self.redraw = true;

    const ctrl_active = self.seat.xkb_state.?.modNameIsActive(
        xkb.names.mod.ctrl,
        @enumFromInt(xkb.State.Component.mods_depressed | xkb.State.Component.mods_latched),
    ) == 1;

    {
        var buffer: [64]u8 = undefined;
        const keysym: xkb.Keysym = @enumFromInt(key);
        _ = keysym.toUTF8(&buffer, 64);
        if (buffer[0] == self.config.keys.move[0]) moveX(grid, -5);
        if (buffer[0] == self.config.keys.move[1]) moveY(grid, 5);
        if (buffer[0] == self.config.keys.move[2]) moveY(grid, -5);
        if (buffer[0] == self.config.keys.move[3]) moveX(grid, 5);

        if (buffer[0] == self.config.keys.resize[0]) resizeX(grid, -5);
        if (buffer[0] == self.config.keys.resize[1]) resizeY(grid, 5);
        if (buffer[0] == self.config.keys.resize[2]) resizeY(grid, -5);
        if (buffer[0] == self.config.keys.resize[3]) resizeX(grid, 5);

        if (buffer[0] == self.config.keys.quit) self.exit = true;
        if (buffer[0] == 'c' and ctrl_active) self.exit = true;
        if (buffer[0] == 8) _ = self.seat.buffer.popOrNull(); // Backspace
    }

    var buffer: [64]u8 = undefined;
    const keynum: xkb.Keysym = @enumFromInt(key);
    _ = keynum.getName(&buffer, 64);
    self.seat.buffer.append(buffer) catch return;
}
