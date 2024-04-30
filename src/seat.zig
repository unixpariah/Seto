const std = @import("std");
const os = std.os;

const xkb = @import("xkbcommon");
const wayland = @import("wayland");
const wl = wayland.client.wl;

const Seto = @import("main.zig").Seto;

pub const Seat = struct {
    wl_seat: ?*wl.Seat = null,
    wl_keyboard: ?*wl.Keyboard = null,
    xkb_state: ?*xkb.State = null,
    xkb_context: *xkb.Context,
    exit: bool = false,

    pub fn new() Seat {
        return Seat{
            .xkb_context = xkb.Context.new(.no_flags) orelse std.debug.panic("", .{}),
        };
    }
};

pub fn seatListener(wl_seat: *wl.Seat, event: wl.Seat.Event, seat: *Seat) void {
    switch (event) {
        .name => {},
        .capabilities => |ev| {
            if (ev.capabilities.keyboard and seat.wl_keyboard == null) {
                const wl_keyboard = wl_seat.getKeyboard() catch return;
                seat.wl_keyboard = wl_keyboard;
                wl_keyboard.setListener(*Seat, keyboardListener, seat);
            } else if (!ev.capabilities.keyboard and seat.wl_keyboard != null) {
                seat.wl_keyboard.?.release();
                seat.wl_keyboard = null;
            }
        },
    }
}

pub fn keyboardListener(_: *wl.Keyboard, event: wl.Keyboard.Event, seat: *Seat) void {
    switch (event) {
        .enter => {},
        .leave => {},
        .keymap => |ev| {
            defer os.close(ev.fd);

            if (ev.format != .xkb_v1) return;

            const keymap_string = os.mmap(null, ev.size, os.PROT.READ, os.MAP.PRIVATE, ev.fd, 0) catch return;
            defer os.munmap(keymap_string);

            const keymap = xkb.Keymap.newFromBuffer(
                seat.xkb_context,
                keymap_string.ptr,
                keymap_string.len - 1,
                .text_v1,
                .no_flags,
            ) orelse return;
            defer keymap.unref();

            const state = xkb.State.new(keymap) orelse return;
            defer state.unref();

            if (seat.xkb_state) |s| s.unref();
            seat.xkb_state = state.ref();
        },
        .modifiers => |ev| {
            if (seat.xkb_state) |xkb_state| {
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

            const xkb_state = seat.xkb_state orelse return;

            // The wayland protocol gives us an input event code. To convert this to an xkb
            // keycode we must add 8.
            const keycode = ev.key + 8;

            const keysym = xkb_state.keyGetOneSym(keycode);
            if (keysym == .NoSymbol) return;

            switch (@intFromEnum(keysym)) {
                xkb.Keysym.q => {
                    seat.exit = true;
                    return;
                },
                xkb.Keysym.c => {
                    const ctrl_active = xkb_state.modNameIsActive(
                        xkb.names.mod.ctrl,
                        @enumFromInt(xkb.State.Component.mods_depressed | xkb.State.Component.mods_latched),
                    ) == 1;

                    if (ctrl_active) {
                        seat.exit = true;
                    }
                },
                xkb.Keysym.Control_L | xkb.Keysym.Control_R => {},
                else => {},
            }
        },
        .repeat_info => {},
    }
}
