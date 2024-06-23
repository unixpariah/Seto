const std = @import("std");

pub fn hexToRgba(hex: ?[]const u8) ![4]f32 {
    if (hex == null) return error.ArgumentMissing;

    const start: u8 = @intFromBool(hex.?[0] == '#');

    if (hex.?.len < 6 + start or hex.?.len > 8 + start) {
        return error.InvalidColor;
    }

    const rgba: [4]f32 = .{
        @floatFromInt(try std.fmt.parseInt(u8, hex.?[0 + start .. 2 + start], 16)),
        @floatFromInt(try std.fmt.parseInt(u8, hex.?[2 + start .. 4 + start], 16)),
        @floatFromInt(try std.fmt.parseInt(u8, hex.?[4 + start .. 6 + start], 16)),
        if (hex.?.len > 6 + start) @floatFromInt(try std.fmt.parseInt(u8, hex.?[6 + start .. 8 + start], 16)) else 255,
    };

    return .{
        rgba[0] / 255,
        rgba[1] / 255,
        rgba[2] / 255,
        rgba[3] / 255,
    };
}

test "hex_to_rgba" {
    const assert = std.debug.assert;

    var rgba = try hexToRgba("#FFFFFFFF");
    for (rgba) |color| {
        assert(color == 1);
    }

    rgba = try hexToRgba("FFFFFFFF");
    for (rgba) |color| {
        assert(color == 1);
    }

    rgba = try hexToRgba("FFFFFF");
    for (rgba) |color| {
        assert(color == 1);
    }

    const too_short = hexToRgba("FFFF");
    assert(too_short == error.InvalidColor);

    const too_long = hexToRgba("FFFFFFFFFF");
    assert(too_long == error.InvalidColor);

    const n_hex = hexToRgba(null);
    assert(n_hex == error.ArgumentMissing);
}
