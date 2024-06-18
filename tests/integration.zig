const std = @import("std");
const assert = std.debug.assert;
const alloc = std.heap.page_allocator;

test "path_not_specified" {
    var child_process = std.process.Child.init(&[_][]const u8{ "zig-out/bin/seto", "-c" }, alloc);
    child_process.stdin_behavior = .Ignore;
    child_process.stdout_behavior = .Ignore;
    child_process.stderr_behavior = .Ignore;
    const exit_status = try child_process.spawnAndWait();

    assert(exit_status.Exited == 1);
}

test "unknown_argument" {
    var child_process = std.process.Child.init(&[_][]const u8{ "zig-out/bin/seto", "-a" }, alloc);
    child_process.stdin_behavior = .Ignore;
    child_process.stdout_behavior = .Ignore;
    child_process.stderr_behavior = .Ignore;
    const exit_status = try child_process.spawnAndWait();

    assert(exit_status.Exited == 1);
}

test "get_version" {
    var child_process = std.process.Child.init(&[_][]const u8{ "zig-out/bin/seto", "-v" }, alloc);
    child_process.stdin_behavior = .Ignore;
    child_process.stdout_behavior = .Ignore;
    child_process.stderr_behavior = .Ignore;
    const exit_status = try child_process.spawnAndWait();

    assert(exit_status.Exited == 0);
}

test "get_help" {
    var child_process = std.process.Child.init(&[_][]const u8{ "zig-out/bin/seto", "-h" }, alloc);
    child_process.stdin_behavior = .Ignore;
    child_process.stdout_behavior = .Ignore;
    child_process.stderr_behavior = .Ignore;
    const exit_status = try child_process.spawnAndWait();

    assert(exit_status.Exited == 0);
}
