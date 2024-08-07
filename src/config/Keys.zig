const std = @import("std");
const c = @import("ffi");

const Lua = @import("ziglua").Lua;
const Font = @import("Font.zig");

bindings: std.AutoHashMap(u32, Function),
search: []u32,
alloc: std.mem.Allocator,

const Self = @This();

pub fn default(alloc: std.mem.Allocator) Self {
    var bindings = std.AutoHashMap(u32, Function).init(alloc);
    bindings.put('H', .{ .move = .{ -5, 0 } }) catch @panic("OOM");
    bindings.put('J', .{ .move = .{ 0, 5 } }) catch @panic("OOM");
    bindings.put('K', .{ .move = .{ 0, -5 } }) catch @panic("OOM");
    bindings.put('L', .{ .move = .{ 5, 0 } }) catch @panic("OOM");
    bindings.put(8, .remove) catch @panic("OOM");
    bindings.put('b', .border_mode) catch @panic("OOM");

    const keys = [_]u32{ 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l' };
    const search = alloc.alloc(u32, 9) catch @panic("OOM");
    @memcpy(search, &keys);

    return .{
        .alloc = alloc,
        .search = search,
        .bindings = bindings,
    };
}

pub fn new(lua: *Lua, alloc: std.mem.Allocator) Self {
    var keys_s = Self.default(alloc);

    _ = lua.pushString("keys");
    _ = lua.getTable(1);
    if (lua.isNil(2)) return keys_s;
    _ = lua.pushString("search");
    _ = lua.getTable(2);
    if (lua.isString(3)) {
        alloc.free(keys_s.search);
        const keys = lua.toString(3) catch unreachable; // Already checked if string
        const utf8_view = std.unicode.Utf8View.init(keys) catch @panic("Failed to initialize utf8 view");

        var buffer = std.ArrayList(u32).init(alloc);
        var iter = utf8_view.iterator();
        while (iter.nextCodepoint()) |codepoint| {
            buffer.append(codepoint) catch @panic("OOM");
        }

        keys_s.search = buffer.toOwnedSlice() catch @panic("OOM");
    }
    lua.pop(1);

    _ = lua.pushString("bindings");
    _ = lua.getTable(2);

    if (!lua.isNil(3)) {
        lua.pushNil();
        while (lua.next(3)) {
            const key: u8 = if (lua.isNumber(4))
                @intFromFloat(lua.toNumber(4) catch unreachable)
            else
                (lua.toString(4) catch unreachable)[0];

            const value: std.meta.Tuple(&.{ [*:0]const u8, ?[2]i32 }) = x: {
                if (lua.isString(5)) {
                    break :x .{ lua.toString(5) catch unreachable, null };
                } else {
                    defer lua.pop(3);
                    const inner_key: [2]u8 = .{ key, 0 };
                    _ = lua.pushString(inner_key[0..1 :0]);
                    _ = lua.getTable(5);
                    _ = lua.pushNil();
                    if (lua.next(5)) {
                        var move_value: [2]i32 = undefined;
                        var index: u8 = 0;
                        _ = lua.pushNil();
                        const function = lua.toString(7) catch unreachable;
                        while (lua.next(8)) : (index += 1) {
                            move_value[index] = @intFromFloat(lua.toNumber(10) catch {
                                std.log.err("{s} expected number\n", .{function});
                                std.process.exit(1);
                            });
                            lua.pop(1);
                        }
                        break :x .{ function, move_value };
                    }
                }
            };

            const len = std.mem.len(value.@"0");
            const func = Function.stringToFunction(value.@"0"[0..len], value.@"1") catch |err| {
                switch (err) {
                    error.UnkownFunction => std.log.err("Unkown function \"{s}\"\n", .{value.@"0"[0..len]}),
                    error.NullValue => std.log.err("Value for function \"{s}\" can't be null\n", .{value.@"0"[0..len]}),
                }
                std.process.exit(1);
            };
            keys_s.bindings.put(key, func) catch @panic("OOM");
            lua.pop(1);
        }
    }
    lua.pop(2);

    return keys_s;
}

pub const Function = union(enum) {
    resize: [2]i32,
    move: [2]i32,
    move_selection: [2]i32,
    border_mode,
    cancel_selection,
    remove,
    quit,

    pub fn stringToFunction(string: []const u8, value: ?[2]i32) !Function {
        if (std.mem.eql(u8, string, "remove")) {
            return .remove;
        } else if (std.mem.eql(u8, string, "quit")) {
            return .quit;
        } else if (std.mem.eql(u8, string, "cancel_selection")) {
            return .cancel_selection;
        } else if (std.mem.eql(u8, string, "border_mode")) {
            return .border_mode;
        } else if (std.mem.eql(u8, string, "move")) {
            return .{ .move = value orelse return error.NullValue };
        } else if (std.mem.eql(u8, string, "resize")) {
            return .{ .resize = value orelse return error.NullValue };
        } else if (std.mem.eql(u8, string, "move_selection")) {
            return .{ .move_selection = value orelse return error.NullValue };
        }

        return error.UnkownFunction;
    }
};
