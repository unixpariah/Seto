# Seto - keyboard based screen selection tool for wayland compositors

## Building

1. Install dependencies:

- zig
- wayland
- libxkbcommon
- cairo

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

Configuration can be done using lua. By default, the configuration file will be located at
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
		color = { 1, 1, 1 },
		highlight_color = { 1, 1, 0 },
		size = 16,
		family = "Arial",
		slant = "Normal",
		weight = "Normal",
	},
	grid = {
		color = { 1, 1, 1, 1 },
		size = { 80, 80 },
		offset = { 0, 0 },
	},
	keys = {
		search = "asdfghjkl",
		bindings = {
			z = { moveX = -5 },   -- Move to left by 5 px on 'z'
			x = { moveY = 5 },    -- Move to bottom by 5px on 'x'
			n = { moveY = -5 },   -- Move to top by 5px on 'n'
			m = { moveX = 5 },    -- Move to right by 5px on 'm'
			Z = { resizeX = -5 }, -- Decrease width by 5px on Shift + 'z'
			X = { resizeY = 5 },  -- Increase height by 5px on Shift + 'x'
			N = { resizeY = -5 }, -- Decrease height by 5px on Shift + 'n'
			M = { resizeX = 5 },  -- Increase width by 5px on Shift + 'm'
			[8] = "remove",       -- Pop last typed character on xkb keycode 8 (Backspace)
			q = "quit",           -- Quit program on 'q'
		},
	},
}
```
