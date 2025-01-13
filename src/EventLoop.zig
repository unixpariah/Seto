const std = @import("std");

pollfds: std.ArrayList(std.posix.pollfd),
polldata: std.ArrayList(PollData),
timeout: i32,

pub const Self = @This();

const PollData = struct {
    callback: *const fn (data: ?*anyopaque) void,
    data: ?*anyopaque,
};

pub fn init(alloc: std.mem.Allocator, timeout: i32) Self {
    return .{
        .pollfds = std.ArrayList(std.posix.pollfd).init(alloc),
        .polldata = std.ArrayList(PollData).init(alloc),
        .timeout = timeout,
    };
}

pub fn initCapacity(alloc: std.mem.Allocator, timeout: i32, capacity: usize) !Self {
    return .{
        .pollfds = try std.ArrayList(std.posix.pollfd).initCapacity(alloc, capacity),
        .polldata = try std.ArrayList(PollData).initCapacity(alloc, capacity),
        .timeout = timeout,
    };
}

pub fn insertSource(
    self: *Self,
    fd: i32,
    comptime T: type,
    callback: *const fn (data: T) void,
    data: T,
) !void {
    try self.pollfds.append(.{ .fd = fd, .events = std.posix.POLL.IN, .revents = 0 });

    try self.polldata.append(.{
        .callback = @ptrCast(callback),
        .data = @ptrCast(data),
    });
}

pub fn insertSourceAssumeCapacity(
    self: *Self,
    fd: i32,
    comptime T: type,
    callback: *const fn (data: T) void,
    data: T,
) void {
    self.pollfds.appendAssumeCapacity(.{ .fd = fd, .events = std.posix.POLL.IN, .revents = 0 });

    self.polldata.appendAssumeCapacity(.{
        .callback = @ptrCast(callback),
        .data = @ptrCast(data),
    });
}

pub fn poll(self: *Self) !void {
    while (true) {
        const events = try std.posix.poll(self.pollfds.items, self.timeout);

        if (events == 0) {
            continue;
        } else if (events < 0) {
            const err = std.os.errno();
            switch (err) {
                std.os.errno.EINTR => continue,
                else => return error.PosixError,
            }
        }

        for (self.pollfds.items, 0..) |pollfd, i| {
            if (pollfd.revents & std.posix.POLL.IN != 0) {
                const poll_data = self.polldata.items[i];
                poll_data.callback(poll_data.data);
            }
        }

        break;
    }
}

pub fn deinit(self: *Self) void {
    self.polldata.deinit();
    self.pollfds.deinit();
}
