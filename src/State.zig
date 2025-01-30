const std = @import("std");
const c = @import("ffi");
const wayland = @import("wayland");
const zgl = @import("zgl");

const wl = wayland.client.wl;
const mem = std.mem;
const posix = std.posix;
const zwlr = wayland.client.zwlr;
const zxdg = wayland.client.zxdg;

const Tree = @import("Tree/NormalTree.zig");
const Output = @import("Output.zig");
const Config = @import("Config.zig");
const Egl = @import("Egl.zig");
const Text = @import("Text.zig");
const EventLoop = @import("EventLoop.zig");
const Trees = @import("Tree/Trees.zig");
const OutputInfo = @import("Output.zig").OutputInfo;
const Seat = @import("seat.zig").Seat;
const Font = @import("config/Font.zig");
const Grid = @import("config/Grid.zig");
const Keys = @import("config/Keys.zig");

pub const TotalDimensions = struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,

    pub fn updateDimensions(outputs: []const OutputInfo) TotalDimensions {
        var min_x: f32 = std.math.floatMax(f32);
        var min_y: f32 = std.math.floatMax(f32);
        var max_x_end: f32 = std.math.floatMin(f32);
        var max_y_end: f32 = std.math.floatMin(f32);

        for (outputs) |output| {
            if (output.width == 0 or output.height == 0) continue;

            const x_end = output.x + output.width;
            const y_end = output.y + output.height;

            min_x = @min(min_x, output.x);
            min_y = @min(min_y, output.y);
            max_x_end = @max(max_x_end, x_end);
            max_y_end = @max(max_y_end, y_end);
        }

        if (min_x == std.math.floatMax(f32)) {
            return .{};
        }

        return .{
            .x = min_x,
            .y = min_y,
            .width = (max_x_end - 1) - min_x,
            .height = (max_y_end - 1) - min_y,
        };
    }
};

const Self = @This();

exit: bool = false,
border_mode: bool = false,
buffer: std.ArrayList(u32),
total_dimensions: TotalDimensions = .{},

pub fn deinit(self: *Self) void {
    self.buffer.deinit();
}

test "single monitor" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{.{ .id = 1, .name = try allocator.dupe(u8, "Single"), .width = 1920, .height = 1080, .x = 0, .y = 0 }};

    const dimensions = TotalDimensions.updateDimensions(&outputs);
    defer outputs[0].deinit(allocator);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 1919), dimensions.width);
    try std.testing.expectEqual(@as(f32, 1079), dimensions.height);
}

test "specific monitor layout" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{
            .id = 1,
            .name = try allocator.dupe(u8, "HDMI-A-7"),
            .width = 1920,
            .height = 1080,
            .x = 960,
            .y = 0,
        },
        .{
            .id = 2,
            .name = try allocator.dupe(u8, "DP-4"),
            .width = 1920,
            .height = 1080,
            .x = 0,
            .y = 1080,
        },
        .{
            .id = 3,
            .name = try allocator.dupe(u8, "DP-5"),
            .width = 1920,
            .height = 1080,
            .x = 1920,
            .y = 1080,
        },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 3839), dimensions.width);
    try std.testing.expectEqual(@as(f32, 2159), dimensions.height);
}

test "vertical stack" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "Top"), .width = 1920, .height = 1080, .x = 0, .y = 0 },
        .{ .id = 2, .name = try allocator.dupe(u8, "Bottom"), .width = 1920, .height = 1080, .x = 0, .y = 1080 },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 1919), dimensions.width);
    try std.testing.expectEqual(@as(f32, 2159), dimensions.height);
}

test "ignore zero-sized monitors" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "Active"), .width = 2560, .height = 1440, .x = 0, .y = 0 },
        .{
            .id = 2,
            .name = try allocator.dupe(u8, "Inactive"),
            .width = 0,
            .height = 0,
            .x = 2560,
            .y = 0,
        },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 2559), dimensions.width);
    try std.testing.expectEqual(@as(f32, 1439), dimensions.height);
}

test "monitors with negative x coordinates" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "Left"), .width = 1920, .height = 1080, .x = -1920, .y = 0 },
        .{ .id = 2, .name = try allocator.dupe(u8, "Right"), .width = 1920, .height = 1080, .x = 0, .y = 0 },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, -1920), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 3839), dimensions.width);
    try std.testing.expectEqual(@as(f32, 1079), dimensions.height);
}

test "monitors with negative y coordinates" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "Top"), .width = 1920, .height = 1080, .x = 0, .y = -1080 },
        .{ .id = 2, .name = try allocator.dupe(u8, "Bottom"), .width = 1920, .height = 1080, .x = 0, .y = 0 },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, -1080), dimensions.y);
    try std.testing.expectEqual(@as(f32, 1919), dimensions.width);
    try std.testing.expectEqual(@as(f32, 2159), dimensions.height);
}

test "single monitor with negative coordinates" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "Negative"), .width = 500, .height = 300, .x = -100, .y = -200 },
    };
    defer outputs[0].deinit(allocator);

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, -100), dimensions.x);
    try std.testing.expectEqual(@as(f32, -200), dimensions.y);
    try std.testing.expectEqual(@as(f32, 499), dimensions.width);
    try std.testing.expectEqual(@as(f32, 299), dimensions.height);
}

test "mixed positive and negative coordinates" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "Monitor1"), .width = 600, .height = 400, .x = -500, .y = 200 },
        .{ .id = 2, .name = try allocator.dupe(u8, "Monitor2"), .width = 800, .height = 500, .x = 300, .y = -300 },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, -500), dimensions.x);
    try std.testing.expectEqual(@as(f32, -300), dimensions.y);
    try std.testing.expectEqual(@as(f32, 1599), dimensions.width);
    try std.testing.expectEqual(@as(f32, 899), dimensions.height);
}

test "ignore zero-sized monitors with negative coordinates" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "Zero"), .width = 0, .height = 0, .x = -100, .y = -200 },
        .{ .id = 2, .name = try allocator.dupe(u8, "Active"), .width = 1920, .height = 1080, .x = 0, .y = 0 },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 1919), dimensions.width);
    try std.testing.expectEqual(@as(f32, 1079), dimensions.height);
}

test "all negative coordinates" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "Left"), .width = 1920, .height = 1080, .x = -3840, .y = -2160 },
        .{ .id = 2, .name = try allocator.dupe(u8, "Right"), .width = 1920, .height = 1080, .x = -1920, .y = -1080 },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, -3840), dimensions.x);
    try std.testing.expectEqual(@as(f32, -2160), dimensions.y);
    try std.testing.expectEqual(@as(f32, 3839), dimensions.width); // (-1920+1920-1) - (-3840)
    try std.testing.expectEqual(@as(f32, 2159), dimensions.height); // (-1080+1080-1) - (-2160)
}

test "minimal valid monitor" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "Pixel"), .width = 1, .height = 1, .x = 100, .y = 100 },
    };
    defer outputs[0].deinit(allocator);

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, 100), dimensions.x);
    try std.testing.expectEqual(@as(f32, 100), dimensions.y);
    try std.testing.expectEqual(@as(f32, 0), dimensions.width); // 1-1 = 0
    try std.testing.expectEqual(@as(f32, 0), dimensions.height); // 1-1 = 0
}

test "grid layout (2x2)" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "TL"), .width = 960, .height = 540, .x = 0, .y = 0 },
        .{ .id = 2, .name = try allocator.dupe(u8, "TR"), .width = 960, .height = 540, .x = 960, .y = 0 },
        .{ .id = 3, .name = try allocator.dupe(u8, "BL"), .width = 960, .height = 540, .x = 0, .y = 540 },
        .{ .id = 4, .name = try allocator.dupe(u8, "BR"), .width = 960, .height = 540, .x = 960, .y = 540 },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 1919), dimensions.width); // (960+960-1) - 0
    try std.testing.expectEqual(@as(f32, 1079), dimensions.height); // (540+540-1) - 0
}

test "no valid monitors" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "Bad1"), .width = 0, .height = 0, .x = 0, .y = 0 },
        .{ .id = 2, .name = try allocator.dupe(u8, "Bad2"), .width = 0, .height = 0, .x = 100, .y = 100 },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 0), dimensions.width);
    try std.testing.expectEqual(@as(f32, 0), dimensions.height);
}

test "mixed overlapping monitors" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "Big"), .width = 3840, .height = 2160, .x = 0, .y = 0 },
        .{ .id = 2, .name = try allocator.dupe(u8, "Small"), .width = 1920, .height = 1080, .x = 960, .y = 540 },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 3839), dimensions.width);
    try std.testing.expectEqual(@as(f32, 2159), dimensions.height);
}

test "wrap-around coordinates" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "West"), .width = 1920, .height = 1080, .x = -3840, .y = 0 },
        .{ .id = 2, .name = try allocator.dupe(u8, "East"), .width = 1920, .height = 1080, .x = 1920, .y = 0 },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, -3840), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 5759), dimensions.width); // (1920+1920-1) - (-3840)
    try std.testing.expectEqual(@as(f32, 1079), dimensions.height);
}
