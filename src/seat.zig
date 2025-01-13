const std = @import("std");

const xkb = @import("xkbcommon");
const wayland = @import("wayland");
const wl = wayland.client.wl;

const Mode = @import("Config.zig").Mode;
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

    const Self = @This();

    pub fn init(alloc: std.mem.Allocator) !Self {
        return .{
            .xkb_context = xkb.Context.new(.no_flags) orelse return error.XkbError,
            .alloc = alloc,
            .repeat = Repeat{ .timer = try Timer.init() },
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.wl_seat) |wl_seat| wl_seat.destroy();
        if (self.wl_keyboard) |wl_keyboard| wl_keyboard.destroy();
        if (self.xkb_state) |xkb_state| xkb_state.unref();
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
            const xkb_state = seto.seat.xkb_state orelse return;

            // The wayland protocol gives us an input event code. To convert this to an xkb
            // keycode we must add 8.
            const keycode = ev.key + 8;

            switch (ev.state) {
                .released => {
                    if (xkb_state.keyGetUtf32(keycode) != seto.seat.repeat.key) return;

                    seto.seat.repeat.key = null;
                    seto.seat.repeat.timer.stop() catch return;
                },
                .pressed => {
                    const keysym = xkb_state.keyGetUtf32(keycode);

                    if (xkb_state.getKeymap().keyRepeats(keycode) == 1) {
                        seto.seat.repeat.timer.start(
                            seto.seat.repeat.delay.?,
                            1000 / seto.seat.repeat.rate.?,
                        ) catch return;
                    } else {
                        seto.seat.repeat.timer.stop() catch return;
                    }

                    seto.seat.repeat.key = keysym;
                    handleKey(seto);
                    seto.render() catch return;
                },
                _ => {},
            }
        },
        .repeat_info => |repeat_key| {
            seto.seat.repeat.delay = @floatFromInt(repeat_key.delay);
            seto.seat.repeat.rate = 60;
        },
    }
}

fn moveSelection(seto: *Seto, value: [2]f32) void {
    switch (seto.config.mode) {
        .Single => return,
        .Region => |*positions| if (positions.*) |*pos| {
            pos[0] += value[0];
            pos[1] += value[1];

            if (pos[0] < seto.state.total_dimensions.x) {
                pos[0] = seto.state.total_dimensions.x;
            } else if (pos[0] > seto.state.total_dimensions.x + seto.state.total_dimensions.width) {
                pos[0] = seto.state.total_dimensions.x + seto.state.total_dimensions.width;
            }

            if (pos[1] < seto.state.total_dimensions.y) {
                pos[1] = seto.state.total_dimensions.y;
            } else if (pos[1] > seto.state.total_dimensions.y + seto.state.total_dimensions.height) {
                pos[1] = seto.state.total_dimensions.y + seto.state.total_dimensions.height;
            }
        },
    }
}

pub fn handleKey(self: *Seto) void {
    const key = self.seat.repeat.key orelse return;
    var trees = self.trees orelse return;

    const keysym_backspace = xkb.Keysym.toUTF32(@enumFromInt(xkb.Keysym.BackSpace));
    const keysym_escape = xkb.Keysym.toUTF32(@enumFromInt(xkb.Keysym.Escape));
    const keysym_interrupt = 3;

    if (key == keysym_backspace) {
        _ = self.state.buffer.popOrNull();
    } else if (key == keysym_interrupt or key == keysym_escape) {
        self.state.exit = true;
    } else if (self.config.keys.bindings.get(@intCast(key))) |function| {
        switch (function) {
            .move => |value| {
                var new_value = value;
                for (0..2) |i| {
                    if (@abs(new_value[i]) >= self.config.grid.size[i]) new_value[i] = @mod(new_value[i], self.config.grid.size[i]);
                }
                trees.move(new_value);
            },
            .resize => |value| {
                var new_value = value;
                for (0..2) |i| {
                    if (self.config.grid.size[i] + value[i] < self.config.grid.min_size and value[i] < 0) {
                        new_value[i] = 0;
                    }
                }

                const depth = trees.normal_tree.depth;
                trees.resize(new_value);
                if (trees.normal_tree.depth != depth) self.state.buffer.clearAndFree();
            },
            .cancel_selection => if (self.config.mode == Mode.Region) {
                self.config.mode = Mode{ .Region = null };
            },
            .move_selection => |value| moveSelection(self, value),
            .border_mode => self.state.border_mode = !self.state.border_mode,
        }
    } else {
        self.state.buffer.append(key) catch @panic("OOM");
        _ = self.printToStdout() catch self.state.buffer.popOrNull();
    }
}
