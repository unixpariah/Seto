const std = @import("std");

pub const Config = struct {
    keys: []const u8 = "asdfghjkl",
    font: Font = Font{},
    background_color: [4]f64 = .{ 0.5, 0.5, 0.5, 0.5 },
    grid: Grid = Grid{},
};

const Font = struct {
    color: [3]f64 = .{ 1, 1, 1 },
    highlight_color: [3]f64 = .{ 1, 1, 0 },
    size: f64 = 16,
    family: [:0]const u8 = "Arial",
};

const Grid = struct {
    color: [4]f64 = .{ 1, 1, 1, 1 },
    size: [2]usize = .{ 80, 80 },
    offset: [2]usize = .{ 0, 0 },
};
