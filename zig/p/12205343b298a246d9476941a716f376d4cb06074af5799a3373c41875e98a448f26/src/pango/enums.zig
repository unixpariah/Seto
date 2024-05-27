/// `pango.Alignment` describes how to align the lines of a `pango.Layout`
/// within the available space.
///
/// If the `pango.Layout` is set to justify using `pango.Layout.setJustify()`,
/// this only affects partial lines.
///
/// See `pango.Layout.setAutoDir()` for how text direction affects the
/// interpretation of `pango.Alignment` values.
pub const Alignment = enum(c_uint) {
    /// Put all available space on the right.
    Left,
    /// Center the line within the available space.
    Center,
    /// Put all available space on the left.
    Right,
};

/// `pango.Direction` represents a direction in the Unicode bidirectional
/// algorithm.
///
/// Not every value in this enumeration makes sense for every usage of
/// `pango.Direction`; for example, the return value of
/// `pango_unichar_direction()` and `pango_find_base_dir()` cannot be
/// `.WeakLtr` or `.WeakRtl`, since every character is either neutral or has a
/// strong direction; on the other hand `.Neutral` doesn’t make sense to pass
/// to `pango_itemize_with_base_dir()`.
///
/// The `.TtbLtr`, `.TtbRtl` values come from an earlier interpretation of this
/// enumeration as the writing direction of a block of text and are no longer
/// used. See `pango.Gravity` for how vertical text is handled in Pango.
///
/// If you are interested in text direction, you should really use fribidi
/// directly. `pango.Direction` is only retained because it is used in some
/// public apis.
pub const Direction = enum(c_uint) {
    // TODO: fix desc
    ///A strong left-to-right direction.
    Ltr,
    /// A strong right-to-left direction.
    Rtl,
    /// Deprecated value; treated the same as `.Rtl`.
    TtbLtr,
    /// Deprecated value; treated the same as `.Ltr`.
    TtbRtl,
    /// A weak left-to-right direction.
    WeakLtr,
    /// A weak right-to-left direction.
    WeakRtl,
    /// No direction specified.
    Neutral,
};

/// `pango.EllipsizeMode` describes what sort of ellipsization should be
/// applied to text.
///
/// In the ellipsization process characters are removed from the text in order
/// to make it fit to a given width and replaced with an ellipsis.
pub const EllipsizeMode = enum(c_uint) {
    /// No ellipsization.
    None,
    /// Omit characters at the start of the text.
    Start,
    /// Omit characters in the middle of the text.
    Middle,
    /// Omit characters at the end of the text.
    End,
};

/// `pango.Gravity` represents the orientation of glyphs in a segment of text.
///
/// This is useful when rendering vertical text layouts. In those situations,
/// the layout is rotated using a non-identity `pango.Matrix`, and then glyph
/// orientation is controlled using `pango.Gravity`.
///
/// Not every value in this enumeration makes sense for every usage of
/// `pango.Gravity`; for example, `.Auto` only can be passed to
/// `pango.Context.setBaseGravity()` and can only be returned by
/// `pango.Context.getBaseGravity()`.
///
/// See also: `pango.GravityHint`.
pub const Gravity = enum(c_uint) {
    /// Glyphs stand upright (default).
    South,
    /// Glyphs are rotated 90 degrees counter-clockwise.
    East,
    /// Glyphs are upside-down.
    North,
    /// Glyphs are rotated 90 degrees clockwise.
    West,
    /// Gravity is resolved from the context matrix.
    Auto,

    // pub fn getForMatrix()
};

/// `pango.GravityHint` defines how horizontal scripts should behave in a
/// vertical context.
///
/// That is, English excerpts in a vertical paragraph for example.
///
/// See also `pango.Gravity`
pub const GravityHint = enum(c_uint) {
    /// Scripts will take their natural gravity based on the base gravity and
    /// the script. This is the default.
    Natural,
    /// Always use the base gravity set, regardless of the script.
    Strong,
    /// For scripts not in their natural direction (eg. Latin in East gravity),
    /// choose per-script gravity such that every script respects the line
    /// progression. This means, Latin and Arabic will take opposite gravities
    /// and both flow top-to-bottom for example.
    Line,
};

/// An enumeration specifying the width of the font relative to other designs
/// within a family.
pub const Stretch = enum(c_uint) {
    /// Ultra condensed width.
    UltraCondensed,
    /// Extra condensed width.
    ExtraCondensed,
    /// Condensed width.
    Condensed,
    /// Semi condensed width.
    SemiCondensed,
    /// The normal width.
    Normal,
    /// Semi expanded width.
    SemiExpanded,
    /// Expanded width.
    Expanded,
    /// Extra expanded width.
    ExtraExpanded,
    /// Ultra expanded width.
    UltraExpanded,
};

/// An enumeration specifying the various slant styles possible for a font.
pub const Style = enum(c_uint) {
    /// The font is upright.
    Normal,
    /// The font is slanted, but in a roman style.
    Oblique,
    /// The font is slanted in an italic style.
    Italic,
};

/// An enumeration specifying capitalization variant of the font.
pub const Variant = enum(c_uint) {
    /// A normal font.
    Normal,
    /// A font with the lower case characters replaced by smaller variants of
    /// the capital characters.
    SmallCaps,
    /// A font with all characters replaced by smaller variants of the capital
    /// characters.
    AllSmallCaps,
    /// A font with the lower case characters replaced by smaller variants of
    /// the capital characters. Petite Caps can be even smaller than Small Caps.
    PetiteCaps,
    /// A font with all characters replaced by smaller variants of the capital
    /// characters. Petite Caps can be even smaller than Small Caps.
    AllPetiteCaps,
    /// A font with the upper case characters replaced by smaller variants of
    /// the capital letters.
    Unicase,
    /// A font with capital letters that are more suitable for all-uppercase
    /// titles.
    TitleCaps,
};

/// An enumeration specifying the weight (boldness) of a font.
///
/// Weight is specified as a numeric value ranging from 100 to 1000. This
/// enumeration simply provides some common, predefined values.
pub const Weight = enum(c_uint) {
    /// The thin weight.
    thin = 100,
    /// The ultralight weight.
    ultralight = 200,
    /// The light weight.
    ligth = 300,
    /// The semilight weight.
    semilight = 350,
    /// The book weight.
    book = 380,
    /// The default weight.
    normal = 400,
    /// The medium weight.
    medium = 500,
    /// The semibold weight.
    semibold = 600,
    /// The bold weight.
    bold = 700,
    /// The ultrabold weight.
    Ultrabold = 800,
    /// The heavy weight.
    heavy = 900,
    /// The ultraheavy weight.
    ultraheavy = 1000,
};

/// `pango.WrapMode` describes how to wrap the lines of a `pango.Layout` to the
/// desired width.
///
/// For `pango.WrapMode.Word`, Pango uses break opportunities that are
/// determined by the Unicode line breaking algorithm. For `.Char`, Pango
/// allows breaking at grapheme boundaries that are determined by the Unicode
/// text segmentation algorithm.
pub const WrapMode = enum(c_uint) {
    /// Wrap lines at word boundaries.
    Word,
    /// Wrap lines at character boundaries.
    Char,
    /// Wrap lines at word boundaries, but fall back to character boundaries if
    /// there is not enough space for a full word.
    WordChar,
};
