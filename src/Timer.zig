const std = @import("std");

fd: i32,

const Self = @This();

pub fn new() !Self {
    const fd = try std.posix.timerfd_create(std.posix.CLOCK.MONOTONIC, .{ .CLOEXEC = true, .NONBLOCK = true });
    return .{ .fd = fd };
}

pub fn start(self: *Self, time: i32, rate: f32) !void {
    const val: std.os.linux.itimerspec = .{
        .it_value = .{
            .tv_sec = @divTrunc(time, 1000),
            .tv_nsec = @mod(time, 1000) * std.time.ns_per_ms,
        },
        .it_interval = .{
            .tv_sec = @intFromFloat(@divTrunc(1000 / rate, 1000)),
            .tv_nsec = @intFromFloat(@mod(1000 / rate, 1000) * std.time.ns_per_ms),
        },
    };

    try std.posix.timerfd_settime(
        @intCast(self.fd),
        .{},
        &val,
        null,
    );
}

pub fn stop(self: *Self) !void {
    const val: std.os.linux.itimerspec = .{
        .it_value = .{
            .tv_sec = 0,
            .tv_nsec = 0,
        },
        .it_interval = .{
            .tv_sec = 0,
            .tv_nsec = 0,
        },
    };

    try std.posix.timerfd_settime(
        @intCast(self.fd),
        .{},
        &val,
        null,
    );
}

pub fn read(self: *Self) !u64 {
    var repeats: u64 = 0;
    _ = try std.posix.read(self.fd, std.mem.asBytes(&repeats));

    return repeats;
}

pub fn getFd(self: *Self) i32 {
    return self.fd;
}
