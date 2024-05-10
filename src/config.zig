const std = @import("std");
const yaml = @import("yaml");

pub const Config = struct {
    keys: []const u8 = "asdfghjkl",
    font: Font = Font{},
    background_color: [4]f64 = .{ 1, 1, 1, 0.4 },
    grid: Grid = Grid{},

    const Self = @This();

    pub fn load(alloc: std.mem.Allocator) Self {
        var a_alloc = std.heap.ArenaAllocator.init(alloc);
        defer a_alloc.deinit();

        const home = std.posix.getenv("HOME") orelse @panic("Home directory not found using default config");
        const config_dir = std.fs.path.join(a_alloc.allocator(), &[_][]const u8{ home, ".config/seto" }) catch @panic("");
        std.fs.accessAbsolute(config_dir, .{}) catch {
            _ = std.fs.makeDirAbsolute(config_dir) catch @panic("");
        };
        const config_file = std.fs.path.join(a_alloc.allocator(), &[_][]const u8{ config_dir, "config.yaml" }) catch @panic("");
        std.fs.accessAbsolute(config_file, .{}) catch {
            _ = std.fs.createFileAbsolute(config_file, .{}) catch @panic("");
        };

        const file = std.fs.openFileAbsolute(config_file, .{}) catch @panic("");
        var buffer: [4098]u8 = undefined;
        _ = file.read(&buffer) catch @panic("");
        std.debug.print("{s}", .{buffer});
        return .{};
    }
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
