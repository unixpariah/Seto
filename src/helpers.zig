const std = @import("std");
const Lua = @import("ziglua").Lua;

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

    {
        const rgba = try hexToRgba("#FFFFFFFF");
        for (rgba) |color| {
            assert(color == 1);
        }
    }

    {
        const rgba = try hexToRgba("FFFFFFFF");
        for (rgba) |color| {
            assert(color == 1);
        }
    }

    {
        const rgba = try hexToRgba("FFFFFF");
        for (rgba) |color| {
            assert(color == 1);
        }
    }

    {
        const rgba = try hexToRgba("7FABE3");
        assert(rgba[0] == 127.0 / 255.0);
        assert(rgba[1] == 171.0 / 255.0);
        assert(rgba[2] == 227.0 / 255.0);
        assert(rgba[3] == 1);
    }

    const too_short = hexToRgba("FFFF");
    assert(too_short == error.InvalidColor);

    const too_long = hexToRgba("FFFFFFFFFF");
    assert(too_long == error.InvalidColor);

    const empty = hexToRgba(null);
    assert(empty == error.ArgumentMissing);
}

pub fn inPlaceReplace(comptime T: type, alloc: std.mem.Allocator, input: *[]const u8, needle: []const u8, replacement: T) void {
    if (needle.len == 0) return;

    const count = std.mem.count(u8, input.*, needle);
    if (count == 0) return;
    const str = if (T == []const u8)
        std.fmt.allocPrint(alloc, "{s}", .{replacement}) catch @panic("OOM")
    else
        std.fmt.allocPrint(alloc, "{any}", .{replacement}) catch @panic("OOM");

    const buffer = alloc.alloc(u8, count * str.len + (input.*.len - needle.len * count)) catch @panic("OOM");
    _ = std.mem.replace(u8, input.*, needle, str, buffer);
    input.* = buffer;
}

test "in_place_replace" {
    const alloc = std.heap.page_allocator;
    const assert = std.debug.assert;

    var format: []const u8 = "h w";
    inPlaceReplace([]const u8, alloc, &format, "h", "hello");
    inPlaceReplace([]const u8, alloc, &format, "w", "world");
    assert(std.mem.eql(u8, format, "hello world"));

    format = "no match";
    inPlaceReplace(i32, alloc, &format, "%z", 42);
    assert(std.mem.eql(u8, format, "no match"));

    format = "no change";
    inPlaceReplace(i32, alloc, &format, "", 42);
    assert(std.mem.eql(u8, format, "no change"));

    format = "full change";
    inPlaceReplace([]const u8, alloc, &format, "full change", "");
    assert(std.mem.eql(u8, format, ""));
}
