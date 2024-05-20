const std = @import("std");
const Seto = @import("main.zig").Seto;

pub fn parseArgs(seto: *Seto) !void {
    _ = seto;
    var args = std.process.args();
    var index: u8 = 0;
    while (args.next()) |arg| : (index += 1) {
        if (index == 0) continue;
        if (std.mem.eql(u8, arg, "-r") or std.mem.eql(u8, arg, "--region"))
            std.debug.print("{s}\n", .{arg})
        else
            std.debug.print("Unkown argument \"{s}\"", .{arg});
    }
}
