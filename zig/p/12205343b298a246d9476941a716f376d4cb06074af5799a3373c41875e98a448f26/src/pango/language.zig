const std = @import("std");
const pango = @import("../pango.zig");
const c = pango.c;

/// The `pango.Language` structure is used to represent a language.
///
/// `pango.Language` pointers can be efficiently copied and compared with each
/// other.
pub const Language = opaque {
    /// Returns the `pango.Language` for the current locale of the process.
    ///
    /// On Unix systems, this is the return value is derived from
    /// `setlocale (LC_CTYPE, NULL)`, and the user can affect this through the
    /// environment variables LC_ALL, LC_CTYPE or LANG (checked in that order).
    /// The locale string typically is in the form lang_COUNTRY, where lang is
    /// an ISO-639 language code, and COUNTRY is an ISO-3166 country code. For
    /// instance, sv_FI for Swedish as written in Finland or pt_BR for
    /// Portuguese as written in Brazil.
    ///
    /// On Windows, the C library does not use any such environment variables,
    /// and setting them won’t affect the behavior of functions like `ctime()`.
    /// The user sets the locale through the Regional Options in the Control
    /// Panel. The C library (in the `setlocale()` function) does not use
    /// country and language codes, but country and language names spelled out
    /// in English. However, this function does check the above environment
    /// variables, and does return a Unix-style locale string based on either
    /// said environment variables or the thread’s current locale.
    ///
    /// Your application should call `setlocale(LC_ALL, "")` for the user
    /// settings to take effect. GTK does this in its initialization functions
    /// automatically (by calling `gtk_set_locale()`). See the `setlocale()`
    /// manpage for more details.
    ///
    /// Note that the default language can change over the life of an
    /// application.
    ///
    /// Also note that this function will not do the right thing if you use
    /// per-thread locales with `uselocale()`. In that case, you should just
    /// call `pango.Language.fromString()` yourself.
    ///
    /// **Returns**
    ///
    /// the default language as a `pango.Language`.
    pub fn getDefault() !*Language {
        return c.pango_language_get_default() orelse error.NullPointer;
    }

    /// Returns the list of languages that the user prefers.
    ///
    /// The list is specified by the PANGO_LANGUAGE or LANGUAGE environment
    /// variables, in order of preference. Note that this list does not
    /// necessarily include the language returned by
    /// `pango.Language.getDefault()`.
    ///
    /// When choosing language-specific resources, such as the sample text
    /// returned by `pango.Language.getSampleString()`, you should first try
    /// the default language, followed by the languages returned by this
    /// function.
    ///
    /// **Returns**
    ///
    /// a slice of `*pango.Language`.
    pub fn getPreferred() []?*Language {
        const ptr: [*:null]?*Language = c.pango_language_get_preferred() orelse return &.{};
        return std.mem.span(ptr);
    }

    /// Convert a language tag to a `pango.Language`.
    ///
    /// The language tag must be in a RFC-3066 format. `pango.Language`
    /// pointers can be efficiently copied (copy the pointer) and compared with
    /// other language tags (compare the pointer.)
    ///
    /// This function first canonicalizes the string by converting it to
    /// lowercase, mapping ‘_’ to ‘-‘, and stripping all characters other than
    /// letters and ‘-‘.
    ///
    /// Use `pango.Language.getDefault()` if you want to get the
    /// `pango.Language` for the current locale of the process.
    ///
    /// **Parameters**
    /// - `language`: A string representing a language tag.
    pub fn fromString(language: [:0]const u8) !*Language {
        return c.pango_language_from_string(language) orelse error.NullPointer;
    }

    /// Gets the RFC-3066 format string representing the given language tag.
    ///
    /// **Returns**
    ///
    /// a string representing the language tag.
    pub fn toString(self: *Language) [:0]const u8 {
        return std.mem.span(c.pango_language_to_string(self) orelse return &.{});
    }

    /// Get a string that is representative of the characters needed to render
    /// a particular language.
    ///
    /// The sample text may be a pangram, but is not necessarily. It is chosen
    /// to be demonstrative of normal text in the language, as well as exposing
    /// font feature requirements unique to the language. It is suitable for
    /// use as sample text in a font selection dialog.
    ///
    /// If Pango does not have a sample string for language, the classic “The
    /// quick brown fox…” is returned. This can be detected by comparing the
    /// returned pointer value to that returned for (non-existent) language
    /// code “xx”. That is, compare to:
    /// ```zig
    /// (pango.Language.fromString("xx") catch unreachable).getSampleString()
    /// ```
    ///
    /// **Returns**
    ///
    /// the sample string.
    pub fn getSampleString(self: *Language) [:0]const u8 {
        return std.mem.span(c.pango_language_get_sample_string(self) orelse return &.{});
    }

    /// Checks if a language tag matches one of the elements in a list of
    /// language ranges.
    ///
    /// A language tag is considered to match a range in the list if the range
    /// is ‘*’, the range is exactly the tag, or the range is a prefix of the
    /// tag, and the character after it in the tag is ‘-‘.
    ///
    /// **Parameters**
    /// - `range_list`: a list of language ranges, separated by ‘;’, ‘:’, ‘,’,
    /// or space characters. Each element must either be ‘*’, or a RFC 3066
    /// language range canonicalized as by `pango.Language.fromString()`.
    ///
    /// **Returns**
    ///
    /// `true` if a match was found.
    pub fn matches(self: *Language, range_list: [:0]const u8) bool {
        return c.pango_language_matches(self, range_list) != 0;
    }
};
