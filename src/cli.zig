const std = @import("std");
const Seto = @import("main.zig").Seto;

pub fn parseArgs(seto: *Seto) !void {
    var args = std.process.args();
    var index: u8 = 0;
    while (args.next()) |arg| : (index += 1) {
        if (index == 0) continue;
        if (std.mem.eql(u8, arg, "-r") or std.mem.eql(u8, arg, "--region"))
            seto.mode = .{ .Region = null }
        else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            std.debug.print("{s}\n", .{help_message});
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "-c") or std.mem.eql(u8, arg, "--config")) {
            const path = args.next() orelse {
                std.debug.print("seto: Argument missing after: \"-c\"\nMore info with \"seto -h\"\n", .{});
                std.process.exit(1);
            };
            std.fs.accessAbsolute(path, .{}) catch {
                std.debug.print("Config file at path \"{s}\" not found\n", .{path});
                std.process.exit(1);
            };
            seto.config_path = seto.alloc.dupeZ(u8, path) catch @panic("OOM");
        } else {
            std.debug.print("Seto: Unkown option argument: \"{s}\"\nMore info with \"seto -h\"\n", .{arg});
            std.process.exit(0);
        }
    }
}

const help_message =
    \\Usage:
    \\  seto: [options...]
    \\
    \\Options:
    \\  -r, --region        Select region of screen
    \\  -h, --help          Print help information
    \\  -c, --config <PATH> Path to config file
;
