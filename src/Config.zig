const std = @import("std");
const fs = std.fs;

const hexToRgba = @import("helpers.zig").hexToRgba;

const Lua = @import("ziglua").Lua;
const Font = @import("config/Font.zig");
const Keys = @import("config//Keys.zig");
const Grid = @import("config/Grid.zig");
const Function = @import("config/Keys.zig").Function;
const Character = @import("config/Keys.zig").Character;
const Color = @import("helpers.zig").Color;

output_format: []const u8 = "%x,%y %wx%h\n",
background_color: Color,
keys: Keys,
font: Font,
grid: Grid,
alloc: std.mem.Allocator,

const Self = @This();

pub fn load(alloc: std.mem.Allocator) Self {
    const config_dir = getPath(alloc) catch {
        const keys = Keys{
            .search = alloc.dupe(u8, "asdfghjkl") catch @panic("OOM"),
            .bindings = std.AutoHashMap(u8, Function).init(alloc),
            .char_info = std.AutoHashMap(u8, Character).init(alloc),
        };
        const font = Font{
            .family = alloc.dupeZ(u8, "sans-serif") catch @panic("OOM"),
            .color = Color.parse("#FFFFFF", alloc) catch unreachable,
            .highlight_color = Color.parse("#FFFF00", alloc) catch unreachable,
        };
        return .{
            .alloc = alloc,
            .font = font,
            .keys = keys,
            .background_color = Color.parse("#FFFFFF66", alloc) catch unreachable,
            .grid = Grid{
                .selected_color = Color.parse("FFFFFF", alloc) catch unreachable,
                .color = Color.parse("FFFFFF", alloc) catch unreachable,
            },
        };
    };
    defer alloc.free(config_dir);

    var lua = Lua.init(&alloc) catch @panic("OOM");
    defer lua.deinit();

    const config_file = fs.path.joinZ(alloc, &[_][]const u8{ config_dir, "config.lua" }) catch @panic("OOM");
    defer alloc.free(config_file);

    lua.doFile(config_file) catch {
        std.log.err("File {s} couldn't be executed by lua interpreter\n", .{config_file});
        std.process.exit(1);
    };

    _ = lua.pushString("background_color");
    _ = lua.getTable(1);
    const background_color = lua.toString(2) catch {
        std.log.err("Background color expected hex value\n", .{});
        std.process.exit(1);
    };

    lua.pop(1);

    return .{
        .alloc = alloc,
        .keys = Keys.new(lua, alloc),
        .grid = Grid.new(lua, alloc),
        .font = Font.new(lua, alloc),
        .background_color = Color.parse(background_color, alloc) catch unreachable,
    };
}

pub fn destroy(self: *Self) void {
    self.alloc.free(self.keys.search);
    self.alloc.free(self.font.family);
    self.keys.char_info.deinit();
    self.keys.bindings.deinit();
}

fn getPath(alloc: std.mem.Allocator) ![]const u8 {
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

            _ = fs.openDirAbsolute(absolute_path, .{}) catch {
                std.log.err("Directory \"{s}\" not found", .{absolute_path});
                std.process.exit(1);
            };

            const config_path = try fs.path.joinZ(alloc, &[_][]const u8{ absolute_path, "config.lua" });
            defer alloc.free(config_path);

            _ = fs.accessAbsolute(config_path, .{}) catch {
                std.log.err("File config.lua not found in \"{s}\" directory", .{absolute_path});
                std.process.exit(1);
            };

            return absolute_path;
        }
    }

    const home = std.posix.getenv("HOME") orelse return error.HomeNotFound;
    const config_dir = try fs.path.join(alloc, &[_][]const u8{ home, ".config/seto" });
    const config_path = fs.path.join(alloc, &[_][]const u8{ config_dir, "config.lua" }) catch |err| {
        alloc.free(config_dir);
        return err;
    };
    defer alloc.free(config_path);

    fs.accessAbsolute(config_path, .{}) catch |err| {
        alloc.free(config_dir);
        return err;
    };

    return config_dir;
}
