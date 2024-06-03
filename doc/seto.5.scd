seto(5)

# NAME
seto - configuration file

# DESCRIPTION

# CONFIGURATION

The seto configuration file defines various parameterss for the client's appearance and functionality. The
following sections describe the configurable options.

*General Settings* \

*background_color*
	Color of background. \

	_Type:_ String \

	_Default:_ #FFFFFF66 \

	_Example:_ #FF000066 \

*Font Settings* \

*font.color*
	Color of font. \

	_Type:_ String \

	_Default:_ #FFFFFFFF \

	_Example:_ #0000FFFF \

*font.highlight_color*
	Color of highlighted characters. \

	_Type:_ String \

	_Default:_ #FFFF00FF \

	_Example:_ #FF0000FF \

*font.size*
	Size of font. \

	_Type:_ Integer \

	_Default:_ 16 \

	_Example:_ 22 \

*font.family*
	Family of font. \

	_Type:_ String \

	_Default:_ "sans-serif" \

	_Example:_ "JetBrainsMono Nerd Font" \

*font.style*
	Style of font \

	_Type:_ String \

	_Default:_ "Normal" \

	_Example:_ "Italic" \

*font.weight*
	Weight of font. \

	_Type:_ Number \

	_Default:_ 400 \

	_Example:_ 1000 \

*font.variant*
	Variant of font. \

	_Type:_ String \

	_Default:_ "Normal" \

	_Example:_ "AllPetiteCaps" \

*font.gravity*
	Gravity of font. \

	_Type_: String \

	_Default:_ "Auto" \

	_Example:_ "South" \

*font.stretch*
	Stretch of font \

	_Type:_ String \

	_Default:_ "Normal" \

	_Example:_ "UltraCondensed" \

*font.offset*
	Relative position of font on grid. \

	_Type:_ [2]: Integer \

	_Default:_ { 5, 5 } \

	_Example:_ { -35, -25 } \

*Grid Settings*

*grid.color*
	Color of grid lines. \

	_Type:_ String \

	_Default:_ #FFFFFFFF \

	_Example:_ #FF0000FF \

*grid.line_width*
	Width of grid lines. \

	_Type:_ Integer \

	_Default:_ 2 \

	_Example:_ 10 \

*grid.size*
	Size of each square. \

	_Type:_ [2]: Integer \

	_Default:_ { 80, 80 } \

	_Example:_ {10, 10} \

*grid.offset*
	Initial relative position of grid. \

	_Type:_ [2]: Integer \

	_Default:_ { 0, 0 } \

	_Example:_ {10, 10} \

*grid.selected_color*
	Color of selected position (Applies only when using *--region* option). \

	_Type:_ String \

	_Default:_ #FF0000FF \

	_Example:_ #FFFF00FF \

*grid.selected_line_width:*
	Width of selected position (Applies only when using *--region* option).

	_Type:_ Integer

	_Default:_ 2

	_Example:_ 10

# Keybindings

*keys.search:*
	Keys used to select screen. \

	_Type:_ String \

	_Default:_ "asdfghjkl" \

	_Example:_ "qwerty" \

*keys.bindings:*
	Functions bound to keys. \

	_Type:_ Table of keys and functions \

	_Default:_ [ ] \

	_Example:_ \

	```
	{
		z = { move = { -5, 0 } },
		x = { move = { 0, 5 } },
		n = { move = { 0, -5 } },
		m = { move = { 5, 0 } },
		Z = { resize = { -5, 0 } },
		X = { resize = { 0, 5 } },
		N = { resize = { 0, -5 } },
		M = { resize = { 5, 0 } },
		H = { move_selection = { -5, 0 } },
		J = { move_selection = { 0, 5 } },
		K = { move_selection = { 0, -5 } },
		L = { move_selection = { 5, 0 } },
		c = "cancel_selection",
		[8] = "remove",
		q = "quit",
	}
	```

# COLORS

Colors may be specified in #RRGGBB or #RRGGBBAA format. The # is optional.

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

move _x,y_				Move grid by specified amount.

resize _x,y_			Resize grid by specified amount.

move_selection _x,y_		Move selected position when using *--region* option by specified amount.

cancel_selection		Cancel selected position when using *--region*.

remove				Remove last character from buffer.

quit					Cancel the selection and exit seto.

By default only function that is bound is quit on *Ctrl+c* which cannot be
overwritten or unbound. Keys to be bound can be specified in xkb keycode or
plain string.

# EXAMPLE CONFIGURATION

```
return {
	background_color = "#FFFFFF66",
	font = {
		color = "#FFFFFF",
		highlight_color = "#FFFF00FF",
		size = 16,
		family = "JetBrainsMono Nerd Font",
		style = "Normal",
		weight = 1000,
		variant = "Normal",
		gravity = "Auto",
		stretch = "Normal",
		offset = { 5, 5 },
	},
	grid = {
		color = "#FFFFFFFF",
		line_width = 2,
		size = { 80, 80 },
		offset = { 0, 0 },
		selected_color = "#FF0000FF",
		selected_line_width = 2,
	},
	keys = {
		search = "asdfghjkl",
		bindings = {
			z = { move = { -5, 0 } },
			x = { move = { 0, 5 } },
			n = { move = { 0, -5 } },
			m = { move = { 5, 0 } },
			Z = { resize = { -5, 0 } },
			X = { resize = { 0, 5 } },
			N = { resize = { 0, -5 } },
			M = { resize = { 5, 0 } },
			H = { move_selection = { -5, 0 } },
			J = { move_selection = { 0, 5 } },
			K = { move_selection = { 0, -5 } },
			L = { move_selection = { 5, 0 } },
			c = "cancel_selection",
			[8] = "remove",
			q = "quit",
		},
	},
}
```
