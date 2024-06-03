const std = @import("std");
const builtin = @import("builtin");
const pango = @import("pango");

const Seto = @import("main.zig").Seto;
const Function = @import("config.zig").Function;

fn hexToRgba(hex: ?[]const u8) ![4]f64 {
    if (hex == null) {
        return error.ArgumentMissing;
    }

    const start: u8 = if (hex.?[0] == '#') 1 else 0;

    if (hex.?.len < 6 + start) {
        return error.InvalidColor;
    }

    const r: f64 = @floatFromInt(try std.fmt.parseInt(u8, hex.?[0 + start .. 2 + start], 16));
    const g: f64 = @floatFromInt(try std.fmt.parseInt(u8, hex.?[2 + start .. 4 + start], 16));
    const b: f64 = @floatFromInt(try std.fmt.parseInt(u8, hex.?[4 + start .. 6 + start], 16));
    const a: f64 = if (hex.?.len > 6 + start) @floatFromInt(try std.fmt.parseInt(u8, hex.?[6 + start .. 8 + start], 16)) else 255;

    return .{
        r / 255,
        g / 255,
        b / 255,
        a / 255,
    };
}

fn printAndExit(comptime message: []const u8, arg: []const u8) noreturn {
    std.debug.print(message, .{arg});
    std.debug.print("{s}\n", .{help_message});
    std.process.exit(1);
}

fn getNextArg(args: *std.process.ArgIterator, current_arg: []const u8) []const u8 {
    return args.next() orelse {
        printAndExit("Argument missing after: \"{s}\"\n", current_arg);
    };
}

fn parseIntArray(arg: ?[]const u8, separator: []const u8) ![2]i32 {
    if (arg == null) {
        return error.ArgumentMissing;
    }
    var iter = std.mem.split(u8, arg.?, separator);
    var result: [2]i32 = undefined;
    var i: usize = 0;
    while (iter.next()) |value| {
        if (i >= 2) break;
        result[i] = try std.fmt.parseInt(i32, value, 10);
        i += 1;
    }
    return result;
}

pub fn parseArgs(seto: *Seto) void {
    const config = &seto.config.?;
    var args = std.process.args();
    var index: u8 = 0;

    while (args.next()) |arg| : (index += 1) {
        if (index == 0) continue;

        if (std.mem.eql(u8, arg, "-r") or std.mem.eql(u8, arg, "--region")) {
            seto.mode = .{ .Region = null };
        } else if (std.mem.eql(u8, arg, "-c") or std.mem.eql(u8, arg, "--config")) {
            _ = getNextArg(&args, arg);
        } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            std.debug.print("{s}\n", .{help_message});
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            std.debug.print("Seto v0.1.0 \nBuild type: {}\nZig {}\n", .{ builtin.mode, builtin.zig_version });
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "--background-color")) {
            config.background_color = hexToRgba(getNextArg(&args, arg)) catch printAndExit("Failed to parse hex value {s}\n", arg);
        } else if (std.mem.eql(u8, arg, "--font-size")) {
            const font_size = getNextArg(&args, arg);
            config.font.size = std.fmt.parseFloat(f64, font_size) catch printAndExit("Incorrect argument for \"{s}\"\n", arg);
        } else if (std.mem.eql(u8, arg, "--font-family")) {
            seto.alloc.free(config.font.family);
            config.font.family = seto.alloc.dupeZ(u8, getNextArg(&args, arg)) catch @panic("OOM");
        } else if (std.mem.eql(u8, arg, "--font-weight")) {
            const font_weight = std.fmt.parseInt(u32, getNextArg(&args, arg), 10) catch {
                std.debug.print("Font weight should be a number\n", .{});
                std.process.exit(1);
            };
            config.font.weight = std.meta.intToEnum(pango.Weight, font_weight) catch |err| @panic(@errorName(err));
        } else if (std.mem.eql(u8, arg, "--font-style")) {
            config.font.style = getStyle(pango.Style, getNextArg(&args, arg));
        } else if (std.mem.eql(u8, arg, "--font-variant")) {
            config.font.variant = getStyle(pango.Variant, getNextArg(&args, arg));
        } else if (std.mem.eql(u8, arg, "--font-gravity")) {
            config.font.gravity = getStyle(pango.Gravity, getNextArg(&args, arg));
        } else if (std.mem.eql(u8, arg, "--font-stretch")) {
            config.font.stretch = getStyle(pango.Stretch, getNextArg(&args, arg));
        } else if (std.mem.eql(u8, arg, "--font-offset")) {
            config.font.offset = parseIntArray(getNextArg(&args, arg), ",") catch printAndExit("Incorrect argument for \"{s}\"\n", arg);
        } else if (std.mem.eql(u8, arg, "--grid-size")) {
            config.grid.size = parseIntArray(getNextArg(&args, arg), ",") catch printAndExit("Incorrect argument for \"{s}\"\n", arg);
        } else if (std.mem.eql(u8, arg, "--grid-offset")) {
            config.grid.offset = parseIntArray(getNextArg(&args, arg), ",") catch printAndExit("Incorrect argument for \"{s}\"\n", arg);
        } else if (std.mem.eql(u8, arg, "--line-width")) {
            const line_width = getNextArg(&args, arg);
            config.grid.line_width = std.fmt.parseFloat(f64, line_width) catch printAndExit("Incorrect argument for \"{s}\"\n", arg);
        } else if (std.mem.eql(u8, arg, "--selected-line-width")) {
            const line_width = getNextArg(&args, arg);
            config.grid.selected_line_width = std.fmt.parseFloat(f64, line_width) catch printAndExit("Incorrect argument for --line-width {s}\n", line_width);
        } else if (std.mem.eql(u8, arg, "--search-keys") or std.mem.eql(u8, arg, "-s")) {
            seto.alloc.free(config.keys.search);
            config.keys.search = seto.alloc.dupe(u8, getNextArg(&args, arg)) catch @panic("OOM");
        } else if (std.mem.eql(u8, arg, "--font-color")) {
            config.font.color = hexToRgba(getNextArg(&args, arg)) catch printAndExit("Failed to parse hex value {s}\n", arg);
        } else if (std.mem.eql(u8, arg, "--highlight-color")) {
            config.font.highlight_color = hexToRgba(getNextArg(&args, arg)) catch printAndExit("Failed to parse hex value {s}\n", arg);
        } else if (std.mem.eql(u8, arg, "--grid-color")) {
            config.grid.color = hexToRgba(getNextArg(&args, arg)) catch printAndExit("Failed to parse hex value {s}\n", arg);
        } else if (std.mem.eql(u8, arg, "--grid-selected-color")) {
            config.grid.selected_color = hexToRgba(getNextArg(&args, arg)) catch printAndExit("Failed to parse hex value {s}\n", arg);
        } else if (std.mem.eql(u8, arg, "--format") or std.mem.eql(u8, arg, "-f")) {
            config.output_format = getNextArg(&args, arg);
        } else if (std.mem.eql(u8, arg, "--function") or std.mem.eql(u8, arg, "-F")) {
            const key = getNextArg(&args, arg);
            const function = getNextArg(&args, arg);
            const values = args.next();
            const func = if (values) |nn_values|
                Function.stringToFunction(function, parseIntArray(nn_values, ",") catch printAndExit("Failed to parse values for function {s}\n", nn_values)) catch printAndExit("Failed to parse function {s}\n", function)
            else
                Function.stringToFunction(function, null) catch printAndExit("Failed to parse function {s}\n", function);

            config.keys.bindings.put(key[0], func) catch printAndExit("Failed to store function binding: \"{s}\"\n", key);
        } else {
            printAndExit("Unknown option argument \"{s}\"\n", arg);
        }
    }
}

fn getStyle(comptime T: type, arg: ?[]const u8) T {
    const c_arg = arg orelse {
        std.debug.print("Missing Argument\n", .{});
        std.debug.print("{s}\n", .{help_message});
        std.process.exit(1);
    };
    return std.meta.stringToEnum(T, c_arg) orelse {
        std.debug.print("Option \"{s}\" does not exist\n", .{c_arg});
        std.debug.print("{s}\n", .{help_message});
        std.process.exit(1);
    };
}

const help_message =
    \\Usage:
    \\  seto [options...]
    \\
    \\Settings:
    \\  -r, --region                               Select region of screen
    \\  -c, --config <PATH>                        Specifies config file
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
    \\  --font-weight <INT>                        Set font weight
    \\  --font-style <STRING>                      Set font style
    \\  --font-variant <STRING>                    Set font variant
    \\  --font-gravity <STRING>                    Set font gravity
    \\  --font-stretch <STRING>                    Set font stretch
    \\  --font-offset <INT,INT>                    Change position of text on grid
    \\
    \\Grid styling:
    \\  --grid-color <HEX>                         Set color of grid
    \\  --grid-size <INT,INT>                      Set size of each square
    \\  --grid-offset <INT,INT>                    Change default position of grid
    \\  --grid-selected-color <HEX>                Change color of selected position in region mode
    \\  --line-width <FLOAT>                       Set width of grid lines
    \\  --selected-line-width <FLOAT>                Change line width of selected position in region mode
    \\
    \\Keybindings:
    \\  -s, --search-keys <STRING>                 Set keys used to search
    \\  -F, --function <STRING> <STRING> [INT,INT] Bind function to a key
;
