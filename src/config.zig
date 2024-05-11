const std = @import("std");
const yaml = @import("yaml");
const fs = std.fs;

pub const Config = struct {
    background_color: [4]f64 = .{ 1, 1, 1, 0.4 },
    keys: Keys = Keys{},
    font: Font = Font{},
    grid: Grid = Grid{},

    const Self = @This();

    pub fn load(allocator: std.mem.Allocator) !Self {
        var a_alloc = std.heap.ArenaAllocator.init(allocator);
        const alloc = a_alloc.allocator();
        defer a_alloc.deinit();

        const home = std.posix.getenv("HOME") orelse return error.HomeNotFound;
        const config_dir = try fs.path.join(alloc, &[_][]const u8{ home, ".config/seto" });
        fs.accessAbsolute(config_dir, .{}) catch {
            _ = try fs.makeDirAbsolute(config_dir);
        };
        const config_file = try fs.path.join(alloc, &[_][]const u8{ config_dir, "config.yaml" });
        fs.accessAbsolute(config_file, .{}) catch {
            const file = try fs.createFileAbsolute(config_file, .{});
            std.debug.print("Config file not found, creating one at {s}\n", .{config_file});
            _ = try file.write(config);
        };

        return .{};
    }
};

const Font = struct {
    color: [3]f64 = .{ 1, 1, 1 },
    highlight_color: [3]f64 = .{ 1, 1, 0 },
    size: f64 = 16,
    family: [:0]const u8 = "Arial",
};

pub const Grid = struct {
    color: [4]f64 = .{ 1, 1, 1, 1 },
    size: [2]isize = .{ 80, 80 },
    offset: [2]isize = .{ 0, 0 },
};

const Keys = struct {
    quit: u8 = 'q',
    search: []const u8 = "asdfghjkl",
    move: *const [4]u8 = &[_]u8{ 'z', 'x', 'n', 'm' },
    resize: *const [4]u8 = &[_]u8{ 'Z', 'X', 'N', 'M' },
};

const config = "background_color: [ 1, 1, 1, 0.4 ]\nkeys:\n    search: asdfghjkl\n    move: [ z, x, n, m ]\n    resize: [ Z, X, N, M ]\nfont:\n    color: [ 1, 1, 1 ]\n    highlight_color: [ 1, 1, 0 ]\n    size: 16\n    family: Arial\ngrid:\n    color: [ 1, 1, 1, 1]\n    size: [ 80, 80 ]\n    offset:    [ 0, 0 ]";
