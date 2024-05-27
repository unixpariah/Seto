const std = @import("std");
const builtin = @import("builtin");

var arena: ?std.heap.ArenaAllocator = undefined;
pub const tracing = builtin.mode == .Debug;

const ib_T = if (tracing) [16 * 16]usize else [0]usize;
var instructions_buffer: ib_T = undefined;
var ib_end: usize = 0;

const LeakInfo = struct {
    count: usize,
    st: std.builtin.StackTrace,
    type_name: []const u8,
    ptr: *anyopaque,
};
const li_T = if (tracing) [16]LeakInfo else [0]LeakInfo;
var leak_infos: li_T = undefined;
var li_end: usize = 0;

var instructions: []usize = undefined;
var leaks: std.AutoArrayHashMap(usize, LeakInfo) = undefined;

const LeaksWriter = union(enum) {
    FileWriter: std.fs.File.Writer,
    BufferWriter: std.io.FixedBufferStream([]u8).Writer,

    pub fn toAny(self: LeaksWriter) *anyopaque {
        return switch (self) {
            inline else => |val| @ptrCast(val),
        };
    }

    pub fn print(self: LeaksWriter, comptime format: []const u8, args: anytype) anyerror!void {
        return switch (self) {
            inline else => |val| val.print(format, args),
        };
    }

    pub fn writeAll(self: LeaksWriter, bytes: []const u8) anyerror!void {
        return switch (self) {
            inline else => |val| val.writeAll(bytes),
        };
    }

    pub fn writeByte(self: LeaksWriter, byte: u8) anyerror!void {
        return switch (self) {
            inline else => |val| val.writeByte(byte),
        };
    }

    pub fn writeByteNTimes(self: LeaksWriter, byte: u8, n: usize) anyerror!void {
        return switch (self) {
            inline else => |val| val.writeByteNTimes(byte, n),
        };
    }
};

var leaks_writer: LeaksWriter = undefined;
var tty_config: ?std.io.tty.Config = null;

fn init() void {
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    instructions = arena.?.allocator().alloc(usize, 512) catch unreachable;
    tty_config = tty_config orelse std.io.tty.detectConfig(std.io.getStdErr());
    leaks = @TypeOf(leaks).init(arena.?.allocator());
    leaks_writer = LeaksWriter{ .FileWriter = std.io.getStdErr().writer() };
    _ = atexit(&detectLeaks);
}

pub fn markForLeakDetection(address: usize, ptr: anytype) !void {
    if (arena == null) init();

    if (ib_end >= instructions.len) {
        const new_slice = try arena.?.allocator().alloc(usize, instructions.len * 2);
        @memcpy(new_slice[0..instructions.len], instructions);
        instructions = new_slice;
    }

    var leak_info: LeakInfo = undefined;
    leak_info.count = 1;
    leak_info.st.instruction_addresses = instructions[ib_end..];
    leak_info.type_name = trimmedTypeName(@TypeOf(ptr));
    leak_info.ptr = ptr;

    std.debug.captureStackTrace(address, &(leak_info.st));

    try leaks.put(@intFromPtr(ptr), leak_info);
    ib_end += leak_info.st.index;
    li_end += 1;
}

pub fn reference(address: usize, ptr: anytype) void {
    const entry = leaks.getPtr(@intFromPtr(ptr));
    if (entry) |e| {
        e.*.count += 1;
        return;
    }
    markForLeakDetection(address, ptr) catch |e| std.debug.panic("{any}", .{e});
}

pub fn destroy(ptr: *anyopaque) void {
    const entry = leaks.getPtr(@intFromPtr(ptr)) orelse std.debug.panic("Double free!", .{});
    entry.*.count -= 1;
    if (entry.count == 0) {
        _ = leaks.swapRemove(@intFromPtr(ptr));
    }
}

pub fn markAsDestroyed(ptr: *anyopaque) void {
    _ = leaks.swapRemove(@intFromPtr(ptr));
}

pub export fn detectLeaks() void {
    var error_state = false;
    defer {
        if (arena) |a| a.deinit();
        arena = null;
        leak_infos = undefined;
        ib_end = 0;
        li_end = 0;
        if (error_state) @panic("giza safety check failure");
    }
    const writer = leaks_writer;
    var it = leaks.iterator();
    while (it.next()) |pair| {
        error_state = true;
        const debug_info = std.debug.getSelfDebugInfo() catch |err| {
            writer.print("\nUnable to print stack trace: Unable to open debug info: {s}\n", .{@errorName(err)}) catch return;
            return;
        };
        const li = pair.value_ptr;
        writer.print("[giza] (err): Leak detected! {s}@{x} leaked:\n", .{ li.type_name, @intFromPtr(li.ptr) }) catch |err| {
            writer.print("Unable to print stack trace: {s}\n", .{@errorName(err)}) catch return;
        };
        std.debug.writeStackTrace(li.st, writer, arena.?.allocator(), debug_info, tty_config.?) catch |err| {
            writer.print("Unable to print stack trace: {s}\n", .{@errorName(err)}) catch return;
        };
        writer.print("\n", .{}) catch unreachable;
    }
}

pub inline fn trimmedTypeName(comptime T: type) []const u8 {
    comptime {
        var type_name: []const u8 = @typeName(T);
        const start_ptr = std.mem.lastIndexOf(u8, type_name, "*") orelse 0;
        type_name = type_name[start_ptr + 1 ..];
        const startType = std.mem.lastIndexOf(u8, type_name, ".") orelse 0;
        return type_name[startType + 1 ..];
    }
}

test "trimmedTypeName" {
    const E = enum {};
    const T = *E;
    try std.testing.expectEqualStrings("E", trimmedTypeName(T));
}

extern fn atexit(?*const fn () callconv(.C) void) c_int;
