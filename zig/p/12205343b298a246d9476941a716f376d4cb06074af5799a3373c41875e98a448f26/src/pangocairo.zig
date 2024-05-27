pub const c = @import("pangocairo/c.zig");

pub usingnamespace @import("pangocairo/fonts.zig");
pub const context = @import("pangocairo/context.zig");
pub const pango_context = @import("pangocairo/pango_context.zig");

const cairo = @import("cairo");
const pango = @import("pango");
const c_bool = c_int;
pub const ShapeRendererFunc = ?*const fn (cr: ?*cairo.Context, attr: [*c]pango.AttrShape, do_path: c_bool, data: ?*anyopaque) callconv(.C) void;
