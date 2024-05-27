const std = @import("std");
const Seto = @import("main.zig").Seto;

pub fn parseArgs(seto: *Seto) void {
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
            _ = args.next();
        } else {
            std.debug.print("Seto: Unkown option argument: \"{s}\"\nMore info with \"seto -h\"\n", .{arg});
            std.process.exit(0);
        }
    }
}

const help_message =
    \\Usage:
    \\  seto [options...]
    \\
    \\Settings:
    \\  -r, --region                    Select region of screen
    \\  -c, --config <PATH>             Specifies config file
    \\
    \\Miscellaneous:
    \\  -h, --help                      Display help information and quit
    \\  -v, --version                   Display version information and quit
    \\
    \\General styling:
    \\  --background-color <HEX>        Set background color
    \\
    \\Font styling:
    \\  --font-color <HEX>              Set font color
    \\  --highlight-color <HEX>         Set highlighted color
    \\  --font-size <INT>               Set font size
    \\  --font-family "<STRING>"        Set font family
    \\  --font-weight <STRING>          Set font weight
    \\  --font-slant <STRING>           Set font slant
    \\  --font-offset <INT,INT>         Change position of text on grid
    \\
    \\Grid styling:
    \\  --grid-color <HEX>              Set color of grid
    \\  --line-width <FLOAT>            Set width of grid lines
    \\  --grid-size <INT,INT>           Set size of each square
    \\  --grid-offset <INT,INT>         Change default position of grid
    \\  --grid-selected-color <HEX>     Change color of selected position in region mode
    \\  --selected-line-width <INT>     Change line width of selected position in region mode
    \\
    \\Keybindings:
    \\  --search-keys <STRING>          Set keys used to search
    \\  --bind-function <CHAR> <STRING> Bind function to specified key (see man seto for details)
;
