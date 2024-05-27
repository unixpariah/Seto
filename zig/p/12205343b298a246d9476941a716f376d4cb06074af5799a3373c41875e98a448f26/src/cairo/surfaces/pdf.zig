//! PDF Surfaces — Rendering PDF documents
//!
//! ## JBIG2 Images
//!
//! JBIG2 data in PDF must be in the embedded format as described in ISO/IEC
//! 11544. Image specific JBIG2 data must be in `cairo.Surface.MimeType.Jbig2`.
//! Any global segments in the JBIG2 data (segments with page association field
//! set to 0) must be in `.Jbig2Global` mime type. The global data may be
//! shared by multiple images. All images sharing the same global data must set
//! `.Jbig2GlobalId` mime data to a unique identifier. At least one of the
//! images must provide the global data using `.Jbig2Global`. The global data
//! will only be embedded once and shared by all JBIG2 images with the same
//! `.Jbig2GlobalId`.
//!
//! ## CCITT Fax Images
//!
//! The `cairo.Surface.MimeType.CcittFax` mime data requires a number of
//! decoding parameters These parameters are specified using .
//!
//! `.CcittFaxParams` mime data must contain a string of the form
//! "param1=value1 param2=value2 ...".
//!
//! - `Columns`: [required] An integer specifying the width of the image in
//! pixels.
//! - `Rows`: [required] An integer specifying the height of the image in scan
//! lines.
//! - `K`: [optional] An integer identifying the encoding scheme used. < 0 is 2
//! dimensional Group 4, = 0 is Group3 1 dimensional, > 0 is mixed 1 and 2
//! dimensional encoding. Default is 0.
//! - `EndOfLine`: [optional] If true end-of-line bit patterns are present.
//! Default is false.
//! - `EncodedByteAlign`: [optional] If true the end of line is padded with 0
//! bits so the next line begins on a byte boundary. Default is false.
//! - `EndOfBlock`: [optional] If true the data contains an end-of-block
//! pattern. Default is true.
//! - `BlackIs1`: [optional] If true 1 bits are black pixels. Default is false.
//! - `DamagedRowsBeforeError`: [optional] An integer specifying the number of
//! damages rows tolerated before an error occurs. Default is 0.
//!
//! Boolean values may be "true" or "false", or 1 or 0.
//!
//! These parameters are the same as the CCITTFaxDecode parameters in the
//! [PostScript Language Reference](https://www.adobe.com/products/postscript/pdfs/PLRM.pdf)
//! and [Portable Document Format (PDF)](https://www.adobe.com/content/dam/Adobe/en/devnet/pdf/pdfs/PDF32000_2008.pdf).
//! Refer to these documents for further details.
//!
//! An example `cairo.Surface.MimeType.CcittFaxParams` string is:
//! ```code
//! "Columns=10230 Rows=40000 K=1 EndOfLine=true EncodedByteAlign=1 BlackIs1=false"
//! ```

const std = @import("std");

const cairo = @import("../../cairo.zig");
const c = cairo.c;
const safety = @import("safety");

const Mixin = @import("base.zig").Base;
const Status = cairo.Status;
const CairoError = cairo.CairoError;
const WriteFn = cairo.WriteFn;

/// The PDF surface is used to render cairo graphics to Adobe PDF files and is
/// a multi-page vector surface backend.
///
/// The following mime types (`cairo.Surface.MimeType`) are supported: `.Jpeg`,
/// `.Jp2`, `.UniqueId`, `.Jbig2`, `.Jbig2Global`, `.Jbig2GlobalId`,
/// `.CcittFax`, `.CcittFaxParams`.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html)
pub const PdfSurface = opaque {
    pub usingnamespace Mixin(@This());
    pub const OutlineRoot = 0;
    /// `cairo.PdfSurface.OutlineFlags` is used by the
    /// `cairo.PdfSurface.addOutline()` function to specify the attributes of
    /// an outline item. These flags may be bitwise-or'd to produce any
    /// combination of flags.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-outline-flags-t)
    pub const OutlineFlags = enum(c_uint) {
        const Self = @This();
        // TODO: oof, that's a bitfield struct, rework later?
        /// The outline item defaults to open in the PDF viewer
        Open = 1,
        /// The outline item is displayed by the viewer in bold text
        Bold = 2,
        /// The outline item is displayed by the viewer in italic text
        Italic = 4,

        OpenBold = 1 | 2,
        OpenItalic = 1 | 4,
        BoldItalic = 2 | 4,
        OpenBoldItalic = 1 | 2 | 4,

        /// Init `cairo.PdfSurface.OutlineFlags` from list of flags. Relevant
        /// flags are: `.Open`, `.Bold`, `.Italic`. Example:
        /// ```zig
        /// const OutlineFlags = cairo.PdfSurface.OutlineFlags;
        /// const flags = OutlineFlags.init(&.{.Bold, .Italic});
        /// ```
        pub fn init(flags: []const OutlineFlags) OutlineFlags {
            var result: c_uint = 0;
            for (flags) |flag| result |= @intFromEnum(flag);
            return @enumFromInt(result);
        }

        pub fn with(self: OutlineFlags, other: OutlineFlags) OutlineFlags {
            return @enumFromInt(@intFromEnum(self) | @intFromEnum(other));
        }

        pub fn without(self: OutlineFlags, other: OutlineFlags) OutlineFlags {
            return @enumFromInt(@intFromEnum(self) & ~@intFromEnum(other));
        }
    };

    /// cairo.PdfSurface.PdfVersion is used to describe the version number of
    /// the PDF specification that a generated PDF file will conform to.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-version-t)
    pub const PdfVersion = enum(c_uint) {
        /// The version 1.4 of the PDF specification.
        @"1.4",
        /// The version 1.5 of the PDF specification.
        @"1.5",

        /// Get the string representation of the given version id. See
        /// `cairo.PdfSurface.getPdfVersions()` for a way to get the list of
        /// valid version ids.
        ///
        /// **Returns**
        ///
        /// the string associated to given version.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-version-to-string)
        pub fn versionToString(self: PdfVersion) []const u8 {
            const str = c.cairo_pdf_version_to_string(self);
            return std.mem.span(str);
        }
    };

    /// `cairo.PdfSurface.Metadata` is used by the
    /// `cairo.PdfSurface.setMetadata()` function specify the metadata to set.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-metadata-t)
    pub const Metadata = enum(c_uint) {
        /// The document title
        Title,
        /// The document author
        Author,
        /// The document subject
        Subject,
        /// The document keywords
        Keywords,
        /// The document creator
        Creator,
        /// The document creation date
        CreateDate,
        /// The document modification date
        ModDate,
    };

    /// Creates a PDF surface of the specified size in points to be written to
    /// `filename`.
    ///
    /// **Parameters**
    /// - `filename`: a filename for the PDF output (must be writable), `null`
    /// may be used to specify no output. This will generate a PDF surface that
    /// may be queried and used as a source, without generating a temporary
    /// file.
    /// - `width_in_points`: width of the surface, in points (1 point == 1/72.0
    /// inch)
    /// - `height_in_points`: height of the surface, in points (1 point ==
    /// 1/72.0 inch)
    ///
    /// **Returns**
    ///
    /// a pointer to the newly created surface.
    ///
    /// **NOTE**: The caller owns the created surface and should call
    /// `surface.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const surface = cairo.PdfSurface.create(null, 100, 100);
    /// defer surface.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-surface-create)
    pub fn create(filename: ?[:0]const u8, width_in_points: f64, height_in_points: f64) CairoError!*PdfSurface {
        const surface = c.cairo_pdf_surface_create(filename orelse null, width_in_points, height_in_points).?;
        try surface.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), surface);
        return surface;
    }

    /// Creates a PDF surface of the specified size in points to be written
    /// incrementally to the stream represented by `writer`.
    ///
    /// **Parameters**
    /// - `writer`: pointer to a writeable object, e.g. `std.io.Writer` or
    /// `std.fs.File` (it should have a `.writeAll()` function)
    /// - `width_in_points`: width of the surface, in points (1 point == 1/72.0
    /// inch)
    /// - `height_in_points`: height of the surface, in points (1 point ==
    /// 1/72.0 inch)
    ///
    /// **Returns**
    ///
    /// a pointer to the newly created surface.
    ///
    /// **NOTE**: The caller owns the created surface and should call
    /// `surface.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const surface = cairo.PdfSurface.create(null, 100, 100);
    /// defer surface.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-surface-create-for-stream)
    pub fn createForStream(writer: anytype, width_in_points: f64, height_in_points: f64) CairoError!*PdfSurface {
        const writeFn = cairo.createWriteFn(writer);
        const surface = c.cairo_pdf_surface_create_for_stream(writeFn, writer, width_in_points, height_in_points).?;
        try surface.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), surface);
        return surface;
    }

    /// Restricts the generated PDF file to `version`. See
    /// `cairo.PdfSurface.getVersions()` for a list of available version values
    /// that can be used here.
    ///
    /// This function should only be called before any drawing operations have
    /// been performed on the given surface. The simplest way to do this is to
    /// call this function immediately after creating the surface.
    ///
    /// **Parameters**
    /// - `version`: PDF version
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-surface-restrict-to-version)
    pub fn restrictToVersion(self: *PdfSurface, version: PdfSurface.PdfVersion) void {
        c.cairo_pdf_surface_restrict_to_version(self, version);
    }

    /// Used to retrieve the list of supported versions. See
    /// `cairo.PdfSurface.restrictToVersion()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-get-versions)
    pub fn getPdfVersions() []const PdfSurface.PdfVersion {
        var ptr: [*c]PdfVersion = undefined;
        var num_versions: c_int = undefined;
        c.cairo_pdf_get_versions(@ptrCast(&ptr), &num_versions);
        return ptr[0..@intCast(num_versions)];
        // TODO
    }

    /// Changes the size of a PDF surface for the current (and subsequent)
    /// pages.
    ///
    /// This function should only be called before any drawing operations have
    /// been performed on the current page. The simplest way to do this is to
    /// call this function immediately after creating the surface or
    /// immediately after completing a page with either
    /// `cairo.Context.showPage()` or `cairo.Context.copyPage()`.
    ///
    /// - `width_in_points`: new surface width, in points (1 point == 1/72.0
    /// inch)
    /// - `height_in_points`: new surface height, in points (1 point ==
    /// 1/72.0 inch)
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-surface-set-size)
    pub fn setSize(self: *PdfSurface, width_in_points: f64, height_in_points: f64) void {
        c.cairo_pdf_surface_set_size(self, width_in_points, height_in_points);
    }

    /// Add an item to the document outline hierarchy with the name `utf8` that
    /// links to the location specified by `link_attribs`. Link attributes have
    /// the same keys and values as the
    /// [Link Tag](https://www.cairographics.org/manual/cairo-Tags-and-Links.html#link),
    /// excluding the "rect" attribute. The item will be a child of the item
    /// with id `parent_id`. Use `cairo.PdfSurface.OutlineRoot` as the parent
    /// id of top level items.
    ///
    ///
    ///
    /// **Parameters**
    /// - `parent_id`: the id of the parent item or
    /// `cairo.PdfSurface.OutlineRoot` if this is a top level item
    /// - `utf8`: the name of the outline
    /// - `link_attribs`: the link attributes specifying where this outline
    /// links to
    /// - `flags`: outline item flags
    ///
    /// **Returns**
    ///
    /// the id for the added item.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-surface-add-outline)
    pub fn addOutline(self: *PdfSurface, parent_id: i64, utf8: [:0]const u8, link_attribs: [:0]const u8, flags: cairo.PdfSurface.OutlineFlags) i64 {
        return @intCast(c.cairo_pdf_surface_add_outline(self, @intCast(parent_id), utf8, link_attribs, flags));
    }

    /// Set document metadata. The `metadata` `.CreateDate` and `.ModDate`
    /// values must be in ISO-8601 format: YYYY-MM-DDThh:mm:ss. An optional
    /// timezone of the form "[+/-]hh:mm" or "Z" for UTC time can be appended.
    /// All other metadata values can be any UTF-8 string.
    ///
    /// For example:
    /// ```zig
    /// pdf_surface.setMetadata(.Title, "My Document");
    /// pdf_surface.setMetadata(.CreateDate, "2015-12-31T23:59+02:00");
    /// ```
    ///
    /// **Parameters**
    /// - `metadata`: the metadata item to set
    /// - `utf8`: metadata value
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-surface-set-metadata)
    pub fn setMetadata(self: *PdfSurface, metadata: cairo.PdfSurface.Metadata, utf8: [:0]const u8) void {
        c.cairo_pdf_surface_set_metadata(self, metadata, utf8);
    }

    /// Set page label for the current page.
    ///
    /// **Parameters**
    /// - `utf8`: the page label
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-surface-set-page-label)
    pub fn setPageLabel(self: *PdfSurface, utf8: [*c]const u8) void {
        c.cairo_pdf_surface_set_page_label(self, utf8);
    }

    /// Set the thumbnail image size for the current and all subsequent pages.
    /// Setting a width or height of 0 disables thumbnails for the current and
    /// subsequent pages.
    ///
    /// **Parameters**
    /// - `width`: thumbnail width
    /// - `height`: thumbnail height
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-surface-set-thumbnail-size)
    pub fn setThumbnailSize(self: *PdfSurface, width: u32, height: u32) void {
        c.cairo_pdf_surface_set_thumbnail_size(self, @intCast(width), @intCast(height));
    }
};
