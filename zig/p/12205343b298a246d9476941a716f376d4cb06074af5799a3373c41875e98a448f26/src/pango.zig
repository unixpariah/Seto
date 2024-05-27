const std = @import("std");
pub const safety = @import("safety");

pub usingnamespace @import("pango/enums.zig");
pub usingnamespace @import("pango/bit_fields.zig");
pub usingnamespace @import("pango/util.zig");

pub const Matrix = @import("pango/matrix.zig").Matrix;

pub const Context = @import("pango/context.zig").Context;
pub const Layout = @import("pango/layout.zig").Layout;
pub const Language = @import("pango/language.zig").Language;
pub const FontDescription = @import("pango/font_description.zig").FontDescription;
pub const FontMap = @import("pango/font_map.zig").FontMap;
pub const FontFamily = @import("pango/font_family.zig").FontFamily;

pub usingnamespace @import("pango/attributes.zig");

pub const SCALE = 1024;

pub const c = @import("pango/c.zig");

comptime {
    std.testing.refAllDeclsRecursive(@This());
}
