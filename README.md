# Seto - keyboard based screen selection tool for wayland compositors

## Building

1. Install dependencies:

- zig
- wayland
- libxkbcommon
- cairo
- pango

2. Clone the repository:

```bash
git clone https://github.com/unixpariah/seto.git
cd seto
```

2. Build and install

```bash
zig build -Doptimize=ReleaseFast -p /usr/local
```

## Configuration

Configuration can be done using lua. By default, seto will look for config at
`$XDG_HOME_CONFIG/seto/config.lua`.

You can also specify a custom path to your configuration file:

```bash
seto -c <PATH>
```

### Example configuration

```lua
return {
	background_color = { 1, 1, 1, 0.4 },
	font = {
		color = { 1, 1, 1, 1 },
		highlight_color = { 1, 0, 0, 1 },
		size = 16,
		family = "JetBrainsMono Nerd Font",
		slant = "Normal",
		weight = "normal",
		variant = "Normal",
		gravity = "Auto",
		stretch = "Normal",
		offset = { 5, 5 },
	},
	grid = {
		color = { 1, 1, 1, 1 },
		selected_color = { 1, 0, 0, 1 },
		size = { 80, 80 },
		offset = { 0, 0 },
	},
	keys = {
		search = "asdfghjkl",
		bindings = {
			z = { move_x = -5 },          -- Move to left by 5 px on 'z'
			x = { move_y = 5 },           -- Move to bottom by 5px on 'x'
			n = { move_y = -5 },          -- Move to top by 5px on 'n'
			m = { move_x = 5 },           -- Move to right by 5px on 'm'
			Z = { resize_x = -5 },        -- Decrease width by 5px on Shift + 'z'
			X = { resize_y = 5 },         -- Increase height by 5px on Shift + 'x'
			N = { resize_y = -5 },        -- Decrease height by 5px on Shift + 'n'
			M = { resize_x = 5 },         -- Increase width by 5px on Shift + 'm'
            w = { move_selection_x = -5 } -- Move selection to left by 5 px on 'z'
            e = { move_selection_y = 5 }  -- Move selection to bottom by 5px on 'x'
            o = { move_selection_y = -5 } -- Move selection to top by 5px on 'n'
            p = { move_selection_x = 5 }  -- Move selection to right by 5px on 'm'
			c = "cancel_selection",       -- Remove selected position
			[8] = "remove",               -- Pop last typed character on xkb keycode 8 (Backspace)
			q = "quit",                   -- Quit program on 'q'
		},
	},
}
```

## TODO

- Sync redraws with monitors refresh rate
- Finish cli
- Hardware acceleration (mby ???)
