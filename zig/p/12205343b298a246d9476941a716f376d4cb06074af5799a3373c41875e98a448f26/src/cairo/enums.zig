/// Specifies the type of antialiasing to do when rendering text or shapes.
///
/// As it is not necessarily clear from the above what advantages a particular
/// antialias method provides, there is also a set of hints:
/// - `.Fast`: Allow the backend to degrade raster quality for speed
/// - `.Good`: A balance between speed and quality
/// - `.Best`: A high-fidelity, but potentially slow, raster mode
///
/// These make no guarantee on how the backend will perform its rasterisation
/// (if it even rasterises!), nor that they have any differing effect other
/// than to enable some form of antialiasing. In the case of glyph rendering,
/// `.Fast` and `.Good` will be mapped to `.Gray` , with `.Best` being
/// equivalent to `.Subpixel`.
///
/// The interpretation of `.Default` is left entirely up to the backend,
/// typically this will be similar to `.Good`.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-antialias-t)
pub const Antialias = enum(c_uint) {
    /// Use the default antialiasing for the subsystem and target device
    Default,
    /// Use a bilevel alpha mask
    None,
    /// Perform single-color antialiasing (using shades of gray for black text
    /// on a white background, for example)
    Gray,
    /// Perform antialiasing by taking advantage of the order of subpixel
    /// elements on devices such as LCD panels
    Subpixel,
    /// Hint that the backend should perform some antialiasing but prefer speed
    /// over quality
    Fast,
    /// The backend should balance quality against performance
    Good,
    /// Hint that the backend should render at the highest quality, sacrificing
    /// speed if necessary
    Best,
};

/// `cairo.Content` is used to describe the content that a surface will
/// contain, whether color information, alpha information (translucence vs.
/// opacity), or both.
///
/// **Note:** The large values here are designed to keep `cairo.Content` values
/// distinct from `cairo.Surface.Format` values so that the implementation can
/// detect the error if users confuse the two types.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-surface-t.html#cairo-content-t)
pub const Content = enum(c_uint) {
    /// The surface will hold color content only
    Color = 4096,
    /// The surface will hold alpha content only
    Alpha = 8192,
    /// The surface will hold color and alpha content
    ColorAlpha = 12288,
};

/// The subpixel order specifies the order of color elements within each pixel
/// on the display device when rendering with an antialiasing mode of
/// `cairo.Antialias.Subpixel`.
pub const SubpixelOrder = enum(c_uint) {
    /// Use the default subpixel order for for the target device
    Default,
    /// Subpixel elements are arranged horizontally with red at the left
    Rgb,
    /// Subpixel elements are arranged horizontally with blue at the left
    Bgr,
    /// Subpixel elements are arranged vertically with red at the top
    Vrgb,
    /// Subpixel elements are arranged vertically with blue at the top
    Vbgr,
};

pub const CairoError = error{
    OutOfMemory,
    InvalidRestore,
    InvalidPopGroup,
    NoCurrentPoint,
    InvalidMatrix,
    InvalidStatus,
    NullPointer,
    InvalidString,
    InvalidPathData,
    ReadError,
    WriteError,
    SurfaceFinished,
    SurfaceTypeMismatch,
    PatternTypeMismatch,
    InvalidContent,
    InvalidFormat,
    InvalidVisual,
    FileNotFound,
    InvalidDash,
    InvalidDscComment,
    InvalidIndex,
    ClipNotRepresentable,
    TempFileError,
    InvalidStride,
    FontTypeMismatch,
    UserFontImmutable,
    UserFontError,
    NegativeCount,
    InvalidClusters,
    InvalidSlant,
    InvalidWeight,
    InvalidSize,
    UserFontNotImplemented,
    DeviceTypeMismatch,
    DeviceError,
    InvalidMeshConstruction,
    DeviceFinished,
    Jbig2GlobalMissing,
    PngError,
    FreetypeError,
    Win32GdiError,
    TagError,

    UnknownStatus,
};

/// `cairo.Status` is used to indicate errors that can occur when using Cairo.
/// In some cases it is returned directly by functions, but when using
/// `cairo.Context`, the last error, if any, is stored in the context
/// and can be retrieved with `cr.status()`.
///
/// Use `status.toString()` to get a human-readable representation of an error
/// message.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Error-handling.html#cairo-status-t)
pub const Status = enum(c_uint) {
    /// no error has occurred
    Success = 0,

    /// out of memory
    NoMemory,
    /// `cr.restore()` called without matching `cr.save()`
    InvalidRestore,
    /// no saved group to pop, i.e. `cr.popGroup()` without matching
    /// `cr.pushGroup()`
    InvalidPopGroup,
    /// no current point defined
    NoCurrentPoint,
    /// invalid matrix (not invertible)
    InvalidMatrix,
    /// invalid value for an input `cairo.Status`
    InvalidStatus,
    /// `null` pointer
    NullPointer,
    /// input string not valid UTF-8
    InvalidString,
    /// input path data not valid
    InvalidPathData,
    /// error while reading from input stream
    ReadError,
    /// error while writing to output stream
    WriteError,
    /// target surface has been finished
    SurfaceFinished,
    /// the surface type is not appropriate for the operation
    SurfaceTypeMismatch,
    /// the pattern type is not appropriate for the operation
    PatternTypeMismatch,
    /// invalid value for an input `cairo.Content`
    InvalidContent,
    /// invalid value for an input `cairo.Surface.Format`
    InvalidFormat,
    /// invalid value for an input Visual*
    InvalidVisual,
    /// file not found
    FileNotFound,
    /// invalid value for a dash setting
    InvalidDash,
    /// invalid value for a DSC comment
    InvalidDscComment,
    /// invalid index passed to getter
    InvalidIndex,
    /// clip region not representable in desired format
    ClipNotRepresentable,
    /// error creating or writing to a temporary file
    TempFileError,
    /// invalid value for stride
    InvalidStride,
    /// the font type is not appropriate for the operation
    FontTypeMismatch,
    /// the user-font is immutable
    UserFontImmutable,
    /// error occurred in a user-font callback function
    UserFontError,
    /// negative number used where it is not allowed
    NegativeCount,
    /// input clusters do not represent the accompanying text and glyph array
    InvalidClusters,
    /// invalid value for an input `cairo.FontFace.FontSlant`
    InvalidSlant,
    /// invalid value for an input `cairo.FontFace.FontWeight`
    InvalidWeight,
    /// invalid value (typically too big) for the size of the input (surface,
    /// pattern, etc.)
    InvalidSize,
    /// user-font method not implemented
    UserFontNotImplemented,
    /// the device type is not appropriate for the operation
    DeviceTypeMismatch,
    /// an operation to the device caused an unspecified error
    DeviceError,
    /// a mesh pattern construction operation was used outside
    /// of a cairo_mesh_pattern_begin_patch()/cairo_mesh_pattern_end_patch() pair // TODO
    InvalidMeshConstruction,
    /// target device has been finished
    DeviceFinished,
    /// CAIRO_MIME_TYPE_JBIG2_GLOBAL_ID has been used on at least one image but no image provided CAIRO_MIME_TYPE_JBIG2_GLOBAL
    /// // TODO
    Jbig2GlobalMissing,
    /// error occurred in libpng while reading from or writing
    /// to a PNG file
    PngError,
    /// error occurred in libfreetype
    FreetypeError,
    /// error occurred in the Windows Graphics Device Interface
    Win32GdiError,
    /// invalid tag name, attributes, or nesting
    TagError,

    /// this is a special value indicating the number of status values defined
    /// in this enumeration. When using this value, note that the version of
    /// cairo at run-time may have additional status values defined than the
    /// value of this symbol at compile-time
    LastStatus,
    _,

    pub fn toErr(self: Status) CairoError!void {
        return switch (self) {
            .Success => {},
            .NoMemory => CairoError.OutOfMemory,
            .InvalidRestore => CairoError.InvalidRestore,
            .InvalidPopGroup => CairoError.InvalidPopGroup,
            .NoCurrentPoint => CairoError.NoCurrentPoint,
            .InvalidMatrix => CairoError.InvalidMatrix,
            .InvalidStatus => CairoError.InvalidStatus,
            .NullPointer => CairoError.NullPointer,
            .InvalidString => CairoError.InvalidString,
            .InvalidPathData => CairoError.InvalidPathData,
            .ReadError => CairoError.ReadError,
            .WriteError => CairoError.WriteError,
            .SurfaceFinished => CairoError.SurfaceFinished,
            .SurfaceTypeMismatch => CairoError.SurfaceTypeMismatch,
            .PatternTypeMismatch => CairoError.PatternTypeMismatch,
            .InvalidContent => CairoError.InvalidContent,
            .InvalidFormat => CairoError.InvalidFormat,
            .InvalidVisual => CairoError.InvalidVisual,
            .FileNotFound => CairoError.FileNotFound,
            .InvalidDash => CairoError.InvalidDash,
            .InvalidDscComment => CairoError.InvalidDscComment,
            .InvalidIndex => CairoError.InvalidIndex,
            .ClipNotRepresentable => CairoError.ClipNotRepresentable,
            .TempFileError => CairoError.TempFileError,
            .InvalidStride => CairoError.InvalidStride,
            .FontTypeMismatch => CairoError.FontTypeMismatch,
            .UserFontImmutable => CairoError.UserFontImmutable,
            .UserFontError => CairoError.UserFontError,
            .NegativeCount => CairoError.NegativeCount,
            .InvalidClusters => CairoError.InvalidClusters,
            .InvalidSlant => CairoError.InvalidSlant,
            .InvalidWeight => CairoError.InvalidWeight,
            .InvalidSize => CairoError.InvalidSize,
            .UserFontNotImplemented => CairoError.UserFontNotImplemented,
            .DeviceTypeMismatch => CairoError.DeviceTypeMismatch,
            .DeviceError => CairoError.DeviceError,
            .InvalidMeshConstruction => CairoError.InvalidMeshConstruction,
            .DeviceFinished => CairoError.DeviceFinished,
            .Jbig2GlobalMissing => CairoError.Jbig2GlobalMissing,
            .PngError => CairoError.PngError,
            .FreetypeError => CairoError.FreetypeError,
            .Win32GdiError => CairoError.Win32GdiError,
            .TagError => CairoError.TagError,

            else => CairoError.UnknownStatus,
        };
    }
};

/// Specifies whether operations should be recorded.
pub const SurfaceObserverMode = enum(c_uint) {
    // Do not record operations
    Normal,
    // Record operations
    RecordOperations,
};
