/// The bits in a `pango.FontMask` correspond to the set fields in a
/// `pango.FontDescriptions`.
pub const FontMask = packed struct(u32) {
    /// The font family is specified.
    family: bool,
    /// The font style is specified.
    style: bool,
    /// The font variant is specified.
    variant: bool,
    /// The font weight is specified.
    weight: bool,
    /// The font stretch is specified.
    stretch: bool,
    /// The font size is specified.
    size: bool,
    /// The font gravity is specified.
    gravity: bool,
    /// OpenType font variations are specified.
    variations: bool,
    _: u24,
};
