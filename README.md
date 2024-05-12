# Seto - keyboard based screen selection tool for wayland compositors

## Dependencies

- zig
- wayland
- wayland-protocols
- wayland-scanner
- wlroots
- libxkbcommon
- cairo
- libyaml
- pkg-config

## Installation

- **Compile from source**

1 . Install dependencies

```bash
apt-get install zig libwayland libxkbcommon cairo libyaml pkg-config
```

2. Compile and install

```zig
zig build -p /usr/local
```

## Configuration

The configuration files will be generated at XDG_HOME_CONFIG/seto/config.yaml on first run.
