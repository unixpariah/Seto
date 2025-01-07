const std = @import("std");

pollfds: std.ArrayList(std.posix.pollfd),
polldata: std.ArrayList(PollData),
timeout: i32,

const Self = @This();

pub fn init(alloc: std.mem.Allocator, timeout: i32) Self {
    return .{
        .pollfds = std.ArrayList(std.posix.pollfd).init(alloc),
        .polldata = std.ArrayList(PollData).init(alloc),
        .timeout = timeout,
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
    while (true) {
        const events = try std.posix.poll(self.pollfds.items, self.timeout);
        if (events == 0) {
            continue;
        } else if (events == -1) {
            const err = std.os.errno();
            switch (err) {
                std.os.errno.EINTR => {
                    continue;
                },
                else => {
                    return error.PosixError;
                },
            }
        }

        // Process events if no error occurred.
        for (self.pollfds.items, 0..) |pollfd, i| {
            if (pollfd.revents & std.posix.POLL.IN != 0) {
                const poll_data = self.polldata.items[i];
                poll_data.callback(poll_data.data);
            }
        }

        break; // Exit loop after processing.
    }
}

pub fn deinit(self: *Self) void {
    self.polldata.deinit();
    self.pollfds.deinit();
}

const PollData = struct {
    callback: *const fn (data: ?*anyopaque) void,
    data: ?*anyopaque,
};
