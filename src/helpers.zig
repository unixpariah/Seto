const std = @import("std");
const Lua = @import("ziglua").Lua;

pub const Color = struct {
    deg: f32,
    start_color: [4]f32,
    end_color: [4]f32,

    const Self = @This();

    pub fn parse(color: []const u8, alloc: std.mem.Allocator) !Self {
        if (color.len == 0) return error.EmptyColor;

        var color_iter = std.mem.splitScalar(u8, color, ' ');
        var index: u8 = 0;

        var start_color: [4]f32 = undefined;
        var end_color: ?[4]f32 = null;
        var deg: f32 = 0;

        while (color_iter.next()) |val| {
            switch (index) {
                0 => {
                    start_color = try hexToRgba(val);
                },
                1 => {
                    end_color = try hexToRgba(val);
                },
                2 => {
                    if (!std.mem.endsWith(u8, val, "deg")) return error.DegParseError;
                    if (std.mem.count(u8, val, "deg") > 1) return error.DegParseError;

                    const output = try alloc.alloc(u8, val.len - 3);
                    _ = std.mem.replace(u8, val, "deg", "", output);
                    defer alloc.free(output);
                    deg = try std.fmt.parseFloat(f32, output);
                },
                else => return error.TooManyArgs,
            }

            index += 1;
        }

        if (end_color == null) end_color = start_color;

        return .{
            .start_color = start_color,
            .end_color = end_color.?,
            .deg = deg,
        };
    }
};

test "errors" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    var color = Color.parse("", alloc);
    assert(color == error.EmptyColor);

    color = Color.parse("#", alloc);
    assert(color == error.InvalidColor);

    color = Color.parse("#FFFFFF #", alloc);
    assert(color == error.InvalidColor);

    color = Color.parse("#FFFFFF #FFFFFF 90deg henlo", alloc);
    assert(color == error.TooManyArgs);

    color = Color.parse("#FFFFFF #FFFFFF 90", alloc);
    assert(color == error.DegParseError);

    color = Color.parse("#FFFFFF #FFFFFF deg90deg", alloc);
    assert(color == error.DegParseError);
}

test "single color" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    const color = try Color.parse("#FFFFFF", alloc);
    for (color.start_color) |c| {
        assert(c == 1);
    }

    for (color.end_color) |c| {
        assert(c == 1);
    }

    assert(color.deg == 0);
}

test "gradient" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    var color = try Color.parse("#FFFFFF #5D5D5D5D", alloc);
    for (color.start_color) |c| {
        assert(c == 1);
    }

    for (color.end_color) |c| {
        assert(c == 93.0 / 255.0);
    }

    assert(color.deg == 0);

    color = try Color.parse("#9C9C9C9C #ECECECEC 90deg", alloc);

    for (color.start_color) |c| {
        assert(c == 156.0 / 255.0);
    }

    for (color.end_color) |c| {
        assert(c == 236.0 / 255.0);
    }

    assert(color.deg == 90);
}

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
