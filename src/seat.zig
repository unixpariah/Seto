const std = @import("std");
const os = std.os;

const xkb = @import("xkbcommon");
const wayland = @import("wayland");
const wl = wayland.client.wl;

const Seto = @import("main.zig").Seto;

pub const Seat = struct {
    wl_seat: ?*wl.Seat,
    wl_keyboard: ?*wl.Keyboard,
    xkb_state: ?*xkb.State,
    xkb_context: *xkb.Context,

    pub fn new() Seat {
        return Seat{
            .wl_seat = null,
            .wl_keyboard = null,
            .xkb_state = null,
            .xkb_context = xkb.Context.new(.no_flags) orelse std.debug.panic("", .{}),
        };
    }
};

pub fn seatListener(wl_seat: *wl.Seat, event: wl.Seat.Event, seto: *Seto) void {
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
