const std = @import("std");

pub usingnamespace @import("cairo/enums.zig");
pub usingnamespace @import("cairo/util.zig");

pub usingnamespace @import("cairo/surface.zig");
pub const Device = @import("cairo/device.zig").Device;

pub usingnamespace @import("cairo/context.zig");
pub usingnamespace @import("cairo/drawing/pattern.zig");
const path = @import("cairo/drawing/paths.zig");
pub const Path = path.Path;
pub const PathData = path.PathData;
pub const Region = @import("cairo/drawing/regions.zig").Region;

const text = @import("cairo/drawing/text.zig");
pub const Glyph = text.Glyph;
pub const TextCluster = text.TextCluster;
pub const FontFace = @import("cairo/fonts/font_face.zig").FontFace;
pub const ToyFontFace = text.ToyFontFace;
pub usingnamespace @import("cairo/fonts/font_options.zig");
pub usingnamespace @import("cairo/fonts/scaled_font.zig");

pub const c = @import("cairo/c.zig");

test {
    std.testing.refAllDeclsRecursive(@This());
}
