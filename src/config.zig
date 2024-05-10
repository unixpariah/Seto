const std = @import("std");
const yaml = @import("yaml");
const fs = std.fs;

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
        const config_dir = fs.path.join(a_alloc.allocator(), &[_][]const u8{ home, ".config/seto" }) catch @panic("");
        fs.accessAbsolute(config_dir, .{}) catch {
            _ = fs.makeDirAbsolute(config_dir) catch @panic("");
        };
        const config_file = fs.path.join(a_alloc.allocator(), &[_][]const u8{ config_dir, "config.yaml" }) catch @panic("");
        fs.accessAbsolute(config_file, .{}) catch {
            _ = fs.createFileAbsolute(config_file, .{}) catch @panic("");
        };

        const file = fs.openFileAbsolute(config_file, .{}) catch @panic("");
        var buffer: [4098]u8 = undefined;
        _ = file.read(&buffer) catch @panic("");

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
