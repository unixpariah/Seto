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
			z = { move = { -5, 0 } },           -- Move to left by 5 px on 'z'
			x = { move = { 0, 5 } },            -- Move to bottom by 5px on 'x'
			n = { move = { 0, -5 } },           -- Move to top by 5px on 'n'
			m = { move = { 5, 0 } },            -- Move to right by 5px on 'm'
			Z = { resize = { -5, 0 } },         -- Decrease width by 5px on Shift + 'z'
			X = { resize = { 0, 5 } },          -- Increase height by 5px on Shift + 'x'
			N = { resize = { 0, -5 } },         -- Decrease height by 5px on Shift + 'n'
			M = { resize = { 5, 0 } },          -- Increase width by 5px on Shift + 'm'
			H = { move_selection = { -5, 0 } }, -- Move selection to left by 5 px on 'z'
			J = { move_selection = { 0, 5 } },  -- Move selection to bottom by 5px on 'x'
			K = { move_selection = { 0, -5 } }, -- Move selection to top by 5px on 'n'
			L = { move_selection = { 5, 0 } },  -- Move selection to right by 5px on 'm'
			c = "cancel_selection",             -- Remove selected position
			[8] = "remove",                     -- Pop last typed character on xkb keycode 8 (Backspace)
			q = "quit",                         -- Quit program on 'q'
		},
	},
}
```

## TODO

- Hardware acceleration (mby ???)
