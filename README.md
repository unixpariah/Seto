# Seto - keyboard based screen selection tool for wayland compositors

## Building

1. Install dependencies:

- zig
- wayland
- libxkbcommon
- cairo
- pango
- scdoc (optional: man pages)

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
`$XDG_CONFIG_HOME/seto/config.lua`.

You can also specify a custom path to your configuration file:

```bash
seto -c <PATH>
```

## TODO

- Hardware acceleration (mby ???)
