const std = @import("std");
const assert = std.debug.assert;
const alloc = std.heap.page_allocator;

fn spawnChildProcess(cmd: []const []const u8) !std.process.Child.Term {
    var child_process = std.process.Child.init(cmd, alloc);
    child_process.stdin_behavior = .Ignore;
    child_process.stdout_behavior = .Ignore;
    child_process.stderr_behavior = .Ignore;

    return try child_process.spawnAndWait();
}

test "unknown_argument" {
    const exit_status = try spawnChildProcess(&[_][]const u8{ "zig-out/bin/seto", "-a" });
    assert(exit_status.Exited == 1);
}

test "get_version" {
    const exit_status = try spawnChildProcess(&[_][]const u8{ "zig-out/bin/seto", "-v" });
    assert(exit_status.Exited == 0);
}

test "get_help" {
    const exit_status = try spawnChildProcess(&[_][]const u8{ "zig-out/bin/seto", "-h" });
    assert(exit_status.Exited == 0);
}

test "path_not_specified" {
    const exit_status = try spawnChildProcess(&[_][]const u8{ "zig-out/bin/seto", "-c" });
    assert(exit_status.Exited == 1);
}

test "custom_config" {
    const exit_status = try spawnChildProcess(&[_][]const u8{ "zig-out/bin/seto", "-c", "./tests" });
    assert(exit_status.Exited == 0);
}

test "wrong_custom_config" {
    const exit_status = try spawnChildProcess(&[_][]const u8{ "zig-out/bin/seto", "-c", "." });
    assert(exit_status.Exited == 1);
}

test "default_config" {
    const exit_status = try spawnChildProcess(&[_][]const u8{ "zig-out/bin/seto", "-c", "null" });
    assert(exit_status.Exited == 0);
}
