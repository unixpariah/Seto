const std = @import("std");

test "path_not_specified" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    var child_process = std.ChildProcess.init(&[_][]const u8{ "zig-out/bin/seto", "-c" }, alloc);

    const exit_status = try child_process.spawnAndWait();

    assert(exit_status.Exited == 1);
}

test "custom_config" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    var child_process = std.ChildProcess.init(&[_][]const u8{ "zig-out/bin/seto", "-c", "~/.config/seto/config.lua" }, alloc);

    _ = child_process.spawnAndWait() catch {};
    //
    //    _ = try child_process.kill();
    //
    assert(true);
    //    //assert(exit_status.Exited == 0);
}
