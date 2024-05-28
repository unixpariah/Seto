const std = @import("std");
const assert = std.debug.assert;
const alloc = std.heap.page_allocator;

test "path_not_specified" {
    var child_process = std.ChildProcess.init(&[_][]const u8{ "zig-out/bin/seto", "-c" }, alloc);
    const exit_status = try child_process.spawnAndWait();

    assert(exit_status.Exited == 1);
}

test "unknown_argument" {
    var child_process = std.ChildProcess.init(&[_][]const u8{ "zig-out/bin/seto", "-a" }, alloc);
    const exit_status = try child_process.spawnAndWait();

    assert(exit_status.Exited == 1);
}

test "get_version" {
    var child_process = std.ChildProcess.init(&[_][]const u8{ "zig-out/bin/seto", "-v" }, alloc);
    const exit_status = try child_process.spawnAndWait();

    assert(exit_status.Exited == 0);
}

test "get_help" {
    var child_process = std.ChildProcess.init(&[_][]const u8{ "zig-out/bin/seto", "-h" }, alloc);
    const exit_status = try child_process.spawnAndWait();

    assert(exit_status.Exited == 0);
}

test "region" {
    var child_process = std.ChildProcess.init(&[_][]const u8{ "zig-out/bin/seto", "-r" }, alloc);
    child_process.spawn() catch {
        assert(false);
    };

    _ = try child_process.kill();
}

test "no_flags" {
    var child_process = std.ChildProcess.init(&[_][]const u8{"zig-out/bin/seto"}, alloc);
    child_process.spawn() catch {
        assert(false);
    };

    _ = try child_process.kill();
}
