seto(1)

# NAME

seto - Keyboard based screen selection tool for wayland

# SYNOPSIS

*seto* [options...]

# DESCRIPTION

Seto is a command-line utility for selecting a screen using keyboard for wayland
compositors implementing layer-shell protocol.

# OPTIONS

*Generic Program Information*

*-h, --help*
	Display help information and quit.

*-v, --version*
	Display version information and quit.

*General Settings*

*-r, --region*
	Select region of screen.

*-c, --config* _path_
	Specifies path to config file. Pass *null* as argument to use default
	config.

*-f, --format* _format_
	Set format. See *FORMAT* for more details.

*--background-color* _color_
	Set background color.

*Font Settings*
*--highlight-color* _color_
	Set color of pressed keys.

*--font-color* _color_
	Set font color.

*--font-size* _size_
	Set font size.

*--font-family* _family_
	Set font family.

*--font-weight* _weight_
	Set weight of font.

*--font-style* _style_
	Set font style. See *FONT STYLING* for more details.

*--font-variant* _variant_
	Set font variant. See *FONT STYLING* for more details.

*--font-gravity* _gravity_
	Set font gravity. See *FONT STYLING* for more details.

*--font-stretch* _stretch_
	Set font stretch. See *FONT STYLING* for more details.

*--font-offset* _x_,_y_
	Relatively move text on grid.

*Grid Styling*
*--grid-color* _color_
	Set color of grid.

*--grid-size* _width_,_height_
	Set size of each square on grid.

*--grid-offset* _x_,_y_
	Relatively change initial position of grid.

*--line-width* _width_
	Set width of grid lines.

*--grid-selected-color* _color_
	Set color of selected position when using *--region* option.

*--selected-line-width* _width_
	Set width of selected grid line when using *--region* option.

*Keybindings*

*-s, --search-keys* _keys_
	Bind keys used to select screen. No separator between keys required.
	Needs at least two characters.

*-F, --function* _key_ _function_ [_x_,_y_]
	Bind function to key. See *FUNCTIONS* for more details.

# CONFIGURATION

Configuration is done in lua, by default seto looks for config file at
$XDG_CONFIG_HOME/.config/seto/config.lua

# COLORS

Colors may be specified in #RRGGBB or #RRGGBBAA format. The # is optional (When
using #, the argument needs to be quoted or else it will be interpreted by shell
as comment).

# FORMAT

Interpreted sequences are:

%x	The x-coordinate of the selection

%y	The y-coordinate of the selection

%w	The width of the selection

%h	The height of the selection

%X	The x-coordinate of the selection with coordinates relative to the output
	containing the top left corner.

%Y	The y-coordinate of the selection with coordinates relative to the output
	containing the top left corner.

%W	The width of the selection cropped to the output containing the top left
	corner.

%H	The height of the selection cropped to the output containing the top left
	corner.

%l	Label included with region from stdin

%o	The name of the output containing the top left corner, or "<unknown>" if
	not known

The default format is "%x,%y %wx%h\\n".

# FONT STYLING

*FONT STYLE*
	- Normal
	- Italic
	- Oblique

*FONT VARIANT*
	- Normal
	- Unicase
	- SmallCaps
	- TitleCaps
	- PetiteCaps
	- AllSmallCaps
	- AllPetiteCaps

*FONT GRAVITY*
	- Auto
	- East
	- West
	- South
	- North

*FONT STRETCH*
	- Normal
	- Expanded
	- Condensed
	- SemiExpanded
	- SemiCondensed
	- ExtraExpanded
	- ExtraCondensed
	- UltraExpanded
	- UltraCondensed

# FUNCTIONS

Available functions are:

border_selection		Outline all outputs and clear grid in the middle to
make selecting entire screen easier

move _x,y_				Move grid by specified amount.

resize _x,y_			Resize grid by specified amount.

move_selection _x,y_		Move selected position when using *--region* option by specified amount.

cancel_selection		Cancel selected position when using *--region*.

remove				Remove last character from buffer.

quit					Cancel the selection and exit seto.

By default only function that is bound is quit on *Ctrl+c* which cannot be
overwritten or unbound. Keys to be bound can be specified in xkb keycode or
plain string.

# AUTHORS
unixpariah <_https://github.com/unixpariah_>.
