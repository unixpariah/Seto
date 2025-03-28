const std = @import("std");

fd: i32,

const Self = @This();

pub fn init() !Self {
    const fd = try std.posix.timerfd_create(std.os.linux.timerfd_clockid_t.MONOTONIC, .{ .CLOEXEC = true, .NONBLOCK = true });
    return .{ .fd = fd };
}

pub fn start(self: *Self, time: f32, interval: f32) !void {
    const val: std.os.linux.itimerspec = .{
        .it_value = .{
            .sec = @intFromFloat(@divTrunc(time, 1000)),
            .nsec = @intFromFloat(@mod(time, 1000) * std.time.ns_per_ms),
        },
        .it_interval = .{
            .sec = @intFromFloat(@divTrunc(interval, 1000)),
            .nsec = @intFromFloat(@mod(interval, 1000) * std.time.ns_per_ms),
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
            .sec = 0,
            .nsec = 0,
        },
        .it_interval = .{
            .sec = 0,
            .nsec = 0,
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

pub fn getFd(self: *const Self) i32 {
    return self.fd;
}
