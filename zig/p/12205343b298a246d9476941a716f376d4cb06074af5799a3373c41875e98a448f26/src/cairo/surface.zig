const svg = @import("surfaces/svg.zig");
const script = @import("surfaces/script.zig");
const pdf = @import("surfaces/pdf.zig");

pub const ImageSurface = @import("surfaces/image.zig").ImageSurface;
pub const RecordingSurface = @import("surfaces/recording.zig").RecordingSurface;
pub const Surface = @import("surfaces/base.zig").Surface;
pub usingnamespace svg;
pub usingnamespace script;
pub usingnamespace pdf;
pub const Win32Surface = @import("surfaces/win32.zig").Win32Surface;
