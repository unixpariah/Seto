const std = @import("std");
const builtin = @import("builtin");
const helpers = @import("helpers");

const Seto = @import("main.zig").Seto;
const Function = @import("config/Keys.zig").Function;
const Color = helpers.Color;

const hexToRgba = helpers.hexToRgba;

fn parseIntArray(arg: ?[]const u8, separator: []const u8) ![2]i32 {
    var iter = std.mem.split(
        u8,
        arg orelse return error.ArgumentMissing,
        separator,
    );
    var result: [2]i32 = undefined;
    var i: usize = 0;
    while (iter.next()) |value| {
        if (i >= 2) break;
        result[i] = try std.fmt.parseInt(i32, value, 10);
        i += 1;
    }
    return result;
}

const Arguments = enum {
    @"--region",
    @"-r",
    @"--config",
    @"-c",
    @"--format",
    @"-f",

    @"--help",
    @"-h",
    @"--version",
    @"-v",

    @"--background-color",

    @"--highlight-color",
    @"--font-color",
    @"--font-size",
    @"--font-family",
    @"--font-offset",

    @"--grid-color",
    @"--grid-size",
    @"--grid-offset",
    @"--grid-selected-color",
    @"--line-width",
    @"--selected-line-width",

    @"--search-keys",
    @"-s",
    @"--function",
    @"-F",
};

pub fn parseArgs(seto: *Seto) void {
    var args = std.process.args();
    var index: u8 = 0;
    while (args.next()) |arg| : (index += 1) {
        if (index == 0) continue;

        const argument = std.meta.stringToEnum(Arguments, arg) orelse {
            std.log.err("Argument {s} not found", .{arg});
            std.process.exit(1);
        };
        switch (argument) {
            .@"--region", .@"-r" => seto.state.mode = .{ .Region = null },
            .@"--config", .@"-c" => _ = args.skip(), // Just skip it as its handled somewhere else
            .@"--format", .@"-f" => {
                seto.config.output_format = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
            },

            .@"--help", .@"-h" => {
                std.log.info("{s}\n", .{help_message});
                std.process.exit(0);
            },
            .@"--version", .@"-v" => {
                std.log.info("Seto v0.1.0 \nBuild type: {}\nZig {}\n", .{ builtin.mode, builtin.zig_version });
                std.process.exit(0);
            },

            .@"--background-color" => {
                const color = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                seto.config.background_color = Color.parse(color, seto.alloc) catch @panic("Failed to parse background-color");
            },

            .@"--highlight-color" => {
                const color = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                seto.config.font.highlight_color = Color.parse(color, seto.alloc) catch @panic("Failed to parse highlight-color");
            },
            .@"--font-color" => {
                const color = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                seto.config.font.color = Color.parse(color, seto.alloc) catch @panic("Failed to parse font-color");
            },
            .@"--font-size" => {
                const font_size = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                seto.config.font.size = std.fmt.parseFloat(f64, font_size) catch @panic("Failed to parse font-size");
            },
            .@"--font-family" => {
                seto.alloc.free(seto.config.font.family);
                const font_family = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                seto.config.font.family = seto.alloc.dupeZ(u8, font_family) catch @panic("OOM");
            },
            .@"--font-offset" => {
                const font_offset = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                seto.config.font.offset = parseIntArray(font_offset, ",") catch @panic("Failed to parse font-offset");
            },

            .@"--grid-color" => {
                const grid_color = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                seto.config.grid.color = Color.parse(grid_color, seto.alloc) catch @panic("Failed to parse grid-color");
            },
            .@"--grid-size" => {
                const grid_size = args.next();
                seto.config.grid.size = parseIntArray(grid_size, ",") catch @panic("Failed to parse grid-size");
            },
            .@"--grid-offset" => {
                const grid_offset = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                seto.config.grid.offset = parseIntArray(grid_offset, ",") catch @panic("Failed to parse grid-offset");
            },
            .@"--grid-selected-color" => {
                const grid_selected_color = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                seto.config.grid.selected_color = Color.parse(grid_selected_color, seto.alloc) catch @panic("Failed to parse grid-selected-color");
            },
            .@"--line-width" => {
                const line_width = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                seto.config.grid.line_width = std.fmt.parseFloat(f32, line_width) catch @panic("Failed to parse line-width");
            },
            .@"--selected-line-width" => {
                const line_width = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                seto.config.grid.selected_line_width = std.fmt.parseFloat(f32, line_width) catch @panic("Failed to parse line-width");
            },

            .@"--search-keys", .@"-s" => {
                seto.alloc.free(seto.config.keys.search);
                const keys_search = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                seto.config.keys.search = seto.alloc.dupe(u8, keys_search) catch @panic("OOM");
            },
            .@"--function", .@"-F" => {
                // TODO: This looks like it was written with hopes and prayes, will have to come back to it
                const key = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };
                const function = args.next() orelse {
                    std.log.err("Argument missing after: \"{s}\"\n", .{arg});
                    std.process.exit(1);
                };

                var value = args.next();
                if (value != null and std.meta.stringToEnum(Arguments, value.?) != null) {
                    value = null;
                }
                const final = if (value) |v| parseIntArray(v, ",") catch {
                    std.log.err("Failed to parse arguments to {s} function\n", .{function});
                    std.process.exit(1);
                } else null;

                const func = Function.stringToFunction(function, final) catch |err| {
                    switch (err) {
                        error.NullValue => std.log.err("Function {s} is missing an argument\n", .{function}),
                        error.UnkownFunction => std.log.err("Unkown function {s}\n", .{function}),
                    }
                    std.process.exit(1);
                };

                seto.config.keys.bindings.put(key[0], func) catch @panic("OOM");
            },
        }
    }
}

const help_message =
    \\Usage:
    \\  seto [options...]
    \\
    \\Settings:
    \\  -r, --region                               Select region of screen
    \\  -c, --config <PATH>                        Specifies path to config directory
    \\  -f, --format <STRING>                      Specifies format of output
    \\
    \\Miscellaneous:
    \\  -h, --help                                 Display help information and quit
    \\  -v, --version                              Display version information and quit
    \\
    \\General styling:
    \\  --background-color <HEX>                   Set background color
    \\
    \\Font styling:
    \\  --highlight-color <HEX>                    Set highlighted color
    \\  --font-color <HEX>                         Set font color
    \\  --font-size <INT>                          Set font size
    \\  --font-family <STRING>                     Set font family
    \\  --font-offset <INT,INT>                    Change position of text on grid
    \\
    \\Grid styling:
    \\  --grid-color <HEX>                         Set color of grid
    \\  --grid-size <INT,INT>                      Set size of each square
    \\  --grid-offset <INT,INT>                    Change default position of grid
    \\  --grid-selected-color <HEX>                Change color of selected position in region mode
    \\  --line-width <FLOAT>                       Set width of grid lines
    \\  --selected-line-width <FLOAT>              Change line width of selected position in region mode
    \\
    \\Keybindings:
    \\  -s, --search-keys <STRING>                 Set keys used to search
    \\  -F, --function <STRING> <STRING> [INT,INT] Bind function to a key
;
