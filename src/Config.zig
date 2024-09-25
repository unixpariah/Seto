const std = @import("std");
const helpers = @import("helpers");
const fs = std.fs;

const hexToRgba = helpers.hexToRgba;

const Lua = @import("ziglua").Lua;
const Font = @import("config/Font.zig");
const Keys = @import("config//Keys.zig");
const Grid = @import("config/Grid.zig");
const Function = @import("config/Keys.zig").Function;
const Text = @import("config/Text.zig");
const Color = helpers.Color;

output_format: []const u8 = "%x,%y %wx%h\n",
background_color: Color,
keys: Keys,
font: Font,
grid: Grid,
text: Text = undefined,
alloc: std.mem.Allocator,

const Self = @This();

pub fn load(alloc: std.mem.Allocator) !Self {
    const config_path = getPath(alloc) catch {
        return .{
            .alloc = alloc,
            .font = Font.default(alloc),
            .keys = Keys.default(alloc),
            .grid = Grid.default(alloc),
            .background_color = Color.parse("#FFFFFF66", alloc) catch unreachable, // Hardcoded so unwrap is safe
        };
    };
    defer alloc.free(config_path);

    var lua = Lua.init(&alloc) catch @panic("OOM");
    defer lua.deinit();

    lua.doFile(config_path) catch @panic("Lua failed to interpret config file");

    _ = lua.pushString("background_color");
    _ = lua.getTable(1);
    const background_color = lua.toString(2) catch @panic("Expected hex value");

    lua.pop(1);

    const font = Font.init(lua, alloc);
    return .{
        .alloc = alloc,
        .grid = Grid.init(lua, alloc),
        .font = font,
        .keys = try Keys.init(lua, alloc),
        .background_color = Color.parse(background_color, alloc) catch @panic("Failed to parse color"),
    };
}

pub fn deinit(self: *Self) void {
    self.alloc.free(self.keys.search);
    self.alloc.free(self.font.family);
    self.text.deinit();
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

            const absolute_path = try std.fs.cwd().realpathAlloc(alloc, path);
            defer alloc.free(absolute_path);
            const absolute_path_z = try fs.path.joinZ(alloc, &[_][]const u8{absolute_path});

            _ = fs.accessAbsolute(absolute_path_z, .{}) catch {
                std.log.err("File config.lua not found in \"{s}\" directory", .{absolute_path});
                std.process.exit(1);
            };

            return absolute_path_z;
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
