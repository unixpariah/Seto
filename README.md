# Seto - keyboard based screen selection tool for wayland compositors

## Dependencies

- zig
- wayland
- libxkbcommon
- cairo

## Installation

- **Compile from source**

1. Clone repository:

```bash
git clone https://github.com/unixpariah/seto.git && cd seto
```

2 . Install dependencies

- Debian:

```bash
apt-get install zig libwayland libxkbcommon cairo
```

- Arch:

```bash
pacman -S zig wayland libxkbcommon cairo
```

- NixOs:

```bash
nix develop
```

3. Compile and install

```zig
zig build -Doptimize=ReleaseFast -p /usr/local
```
