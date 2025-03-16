const std = @import("std");
const helpers = @import("helpers");
const fs = std.fs;

const parseArgs = @import("cli.zig").parseArgs;
const hexToRgba = helpers.hexToRgba;

const Lua = @import("ziglua").Lua;
const Font = @import("config/Font.zig");
const Keys = @import("config//Keys.zig");
const Grid = @import("config/Grid.zig");
const Function = @import("config/Keys.zig").Function;
const Text = @import("Text.zig");
const Color = helpers.Color;

pub const Mode = union(enum) {
    Region: ?[2]f32,
    Single,
};

output_format: []const u8 = "%x,%y %wx%h\n",
mode: Mode = .Single,
background_color: Color,
keys: *Keys,
font: *Font,
grid: *Grid,
alloc: std.mem.Allocator,

const Self = @This();

pub fn default(alloc: std.mem.Allocator) Self {
    return .{
        .alloc = alloc,
        .font = Font.default(alloc),
        .keys = Keys.default(alloc),
        .grid = Grid.default(alloc),
        .background_color = Color.parse("#FFFFFF66", alloc) catch unreachable, // Hardcoded so unwrap is safe
    };
}

pub inline fn getLuaFile(alloc: std.mem.Allocator) !*Lua {
    var lua = try Lua.init(alloc);

    const config_path = try getPath(alloc);
    defer alloc.free(config_path);
    try lua.doFile(config_path);

    return lua;
}

pub fn load(lua: *Lua, keys: *Keys, grid: *Grid, font: *Font, alloc: std.mem.Allocator) !Self {
    _ = lua.pushString("background_color");
    _ = lua.getTable(1);
    const background_color = lua.toString(2) catch @panic("Expected hex value");

    lua.pop(1);

    var config = Self{
        .alloc = alloc,
        .grid = grid,
        .font = font,
        .keys = keys,
        .background_color = Color.parse(background_color, alloc) catch @panic("Failed to parse color"),
    };
    parseArgs(&config);
    return config;
}

pub fn deinit(self: *const Self) void {
    self.alloc.free(self.keys.search);
    self.alloc.free(self.font.family);
    self.keys.bindings.deinit();
}

fn getPath(alloc: std.mem.Allocator) ![:0]const u8 {
    var args = std.process.args();
    var index: u8 = 0;
    while (args.next()) |arg| : (index += 1) {
        if (std.mem.eql(u8, arg, "-c") or std.mem.eql(u8, arg, "--config")) {
            const path = args.next() orelse {
                std.log.err("Argument missing after: \"-c\"\nMore info with \"seto -h\"\n", .{});
                std.process.exit(1);
            };

            if (std.mem.eql(u8, path, "null")) return error.Null;

            const absolute_path = blk: {
                const absolute_path = try std.fs.cwd().realpathAlloc(alloc, path);
                defer alloc.free(absolute_path);
                break :blk try fs.path.joinZ(alloc, &[_][]const u8{absolute_path});
            };

            _ = fs.accessAbsolute(absolute_path, .{}) catch {
                std.log.err("File config.lua not found in \"{s}\" directory", .{absolute_path});
                std.process.exit(1);
            };

            return absolute_path;
        }
    }

    const home = std.posix.getenv("HOME") orelse @panic("HOME env var not set");
    const config_path = try fs.path.joinZ(alloc, &[_][]const u8{ home, ".config/seto/config.lua" });

    fs.accessAbsolute(config_path, .{}) catch |err| {
        alloc.free(config_path);
        return err;
    };

    return config_path;
}
