const std = @import("std");
const Lua = @import("ziglua").Lua;
const c = @import("ffi");
const hexToRgba = @import("helpers").hexToRgba;

pub const Color = union(enum) {
    solid: struct { color: [4]f32 },
    gradient: struct {
        deg: f32,
        start_color: [4]f32,
        end_color: [4]f32,
    },
    triple_gradient: struct {
        deg: f32,
        start_color: [4]f32,
        mid_color: [4]f32,
        end_color: [4]f32,
    },

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
                0 => start_color = try hexToRgba(val),
                1 => end_color = try hexToRgba(val),
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
            .gradient = .{
                .start_color = start_color,
                .end_color = end_color.?,
                .deg = deg,
            },
        };
    }

    pub fn set(self: *const Self, shader_program: c_uint) void {
        switch (self.*) {
            .gradient => |color| {
                c.glUniform4f(
                    c.glGetUniformLocation(shader_program, "u_startcolor"),
                    color.start_color[0] * color.start_color[3],
                    color.start_color[1] * color.start_color[3],
                    color.start_color[2] * color.start_color[3],
                    color.start_color[3],
                );
                c.glUniform4f(
                    c.glGetUniformLocation(shader_program, "u_endcolor"),
                    color.end_color[0] * color.end_color[3],
                    color.end_color[1] * color.end_color[3],
                    color.end_color[2] * color.end_color[3],
                    color.end_color[3],
                );
                c.glUniform1f(c.glGetUniformLocation(shader_program, "u_degrees"), color.deg);
            },
            else => unreachable,
        }
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

    color = Color.parse("#FFFFFF #FFFFFF deg", alloc);
    assert(color == error.InvalidCharacter);
}

test "single color" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    {
        const color = try Color.parse("#FFFFFF", alloc);
        for (color.start_color) |col| {
            assert(col == 1);
        }

        for (color.end_color) |col| {
            assert(col == 1);
        }

        assert(color.deg == 0);
    }

    {
        const color = Color.parse("#FFFFFF 45deg", alloc);
        assert(color == error.InvalidColor);
    }
}

test "gradient" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    {
        const color = try Color.parse("#FFFFFF #5D5D5D5D", alloc);
        for (color.start_color) |col| {
            assert(col == 1);
        }

        for (color.end_color) |col| {
            assert(col == 93.0 / 255.0);
        }

        assert(color.deg == 0);
    }

    {
        const color = try Color.parse("#9C9C9C9C #ECECECEC 90deg", alloc);

        for (color.start_color) |col| {
            assert(col == 156.0 / 255.0);
        }

        for (color.end_color) |col| {
            assert(col == 236.0 / 255.0);
        }

        assert(color.deg == 90);
    }
}
