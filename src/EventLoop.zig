const std = @import("std");

pollfds: std.ArrayList(std.posix.pollfd),
polldata: std.ArrayList(PollData),

const Self = @This();

pub fn new(alloc: std.mem.Allocator) Self {
    return .{
        .pollfds = std.ArrayList(std.posix.pollfd).init(alloc),
        .polldata = std.ArrayList(PollData).init(alloc),
    };
}

pub fn insertSource(self: *Self, fd: i32, comptime T: type, callback: *const fn (data: T) void, data: T) !void {
    try self.pollfds.append(
        .{ .fd = fd, .events = std.posix.POLL.IN, .revents = 0 },
    );

    try self.polldata.append(.{
        .data = @ptrCast(data),
        .callback = @ptrCast(callback),
    });
}

pub fn poll(self: *Self) !void {
    const events = try std.posix.poll(self.pollfds.items, -1);
    if (events > 0) {
        for (self.pollfds.items, 0..) |pollfd, i| {
            if (pollfd.revents & std.posix.POLL.IN != 0) {
                const poll_data = self.polldata.items[i];
                poll_data.callback(poll_data.data);
            }
        }
    }
}

pub fn destroy(self: *Self) void {
    self.polldata.deinit();
    self.pollfds.deinit();
}

const PollData = struct {
    callback: *const fn (data: ?*anyopaque) void,
    data: ?*anyopaque,
};
