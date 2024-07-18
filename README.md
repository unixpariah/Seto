# Seto

Hardware accelerated keyboard based screen selection tool with all the eye candy you could ever ask for.

## Building

1. Install dependencies:

- zig
- wayland
- libxkbcommon
- libGL
- freetype
- fontconfig
- ydotool (optional: tests)
- scdoc (optional: man pages)

2. Clone the repository:

```bash
git clone https://github.com/unixpariah/seto.git
cd seto
```

2. Build and install

```bash
zig build -Doptimize=ReleaseSafe -p /usr/local
```

## Configuration

Configuration can be done using lua. By default, seto will look for config at
`$XDG_CONFIG_HOME/seto/config.lua`.

You can also specify a custom path to your configuration directory:

```bash
seto -c <PATH>
```

Run `man 5 seto` for more information

## Examples

Select single point and print it to stdout:

```bash
seto
```

Select region instead of single point:

```bash
seto -r
```

Take screenshot with [grim](https://wayland.emersion.fr/grim/)

```bash
grim -g $(./zig-out/bin/seto -r) - | wl-copy -t image/png
```

Output just x and y positions and move mouse using [ydotool](https://github.com/ReimuNotMoe/ydotool) (specific syntax for escaping newline works in bash and zsh but may not in other shells):

```bash
ydotool mousemove -a $(seto -f $'%x %y\n')
```

Took a lot of inspirations from [slurp](https://github.com/emersion/slurp) :)
