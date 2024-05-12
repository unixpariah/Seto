# Seto - keyboard based screen selection tool for wayland compositors

## Dependencies

- zig
- wayland
- libxkbcommon
- cairo
- libyaml

## Installation

- **Compile from source**

1. Clone repository:

```bash
git clone https://github.com/unixpariah/seto.git && cd seto
```

2 . Install dependencies

- Debian:

```bash
apt-get install zig libwayland libxkbcommon cairo libyaml
```

- Arch:

```bash
pacman -S zig wayland libxkbcommon cairo libyaml
```

- NixOs:

```bash
nix develop
```

3. Compile and install

```zig
zig build -p /usr/local
```

## Configuration

The configuration files will be generated at XDG_HOME_CONFIG/seto/config.yaml on first run.
