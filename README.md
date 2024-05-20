# Seto - keyboard based screen selection tool for wayland compositors

## Building

Install dependencies:

- zig
- wayland
- libxkbcommon
- cairo

Run:

```bash
git clone https://github.com/unixpariah/seto.git
cd seto
zig build -Doptimize=ReleaseFast -p /usr/local
```

## Configuration

Configuration file will be created at XDG_HOME_CONFIG/seto/config.lua on first run
