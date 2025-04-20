# Seto

Hardware accelerated keyboard driven screen selection tool.


https://github.com/user-attachments/assets/1d97709c-f17b-4742-a36a-6eee580d06d4

## Installing (NixOS)
Add this to the inputs of your `flake.nix`
```nix
seto = {
  url = "github:unixpariah/seto";
  inputs.nixpkgs.follows = "nixpkgs";
};
```
Then in either `environment.systemPackages` or `home.packages` add the following:
```nix
inputs.seto.packages.${pkgs.system}.default
```

## Installing (Arch Linux)
Clone this repo and run `makepkg -si`

```bash
$ git clone https://github.com/unixpariah/seto.git
$ cd seto
$ makepkg -si
```

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

3. Build and run

```bash
zig build -Dmax-instances=100 -Doptimize=ReleaseSafe run
```

### `--max-instances` (Default: 100)
Controls how many characters can be rendered in a single draw call. 
Higher values typically improve performance but may cause issues on:
- Older GPUs
- Drivers with strict shader array limits

## Configuration

Configuration can be done using lua. By default, seto will look for config at
`~/.config/seto/config.lua`.

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
grim -g $(seto -r) - | wl-copy -t image/png
```

Output just x and y positions move mouse, and click using [ydotool](https://github.com/ReimuNotMoe/ydotool) (specific syntax for escaping newline works in bash and zsh but may not in other shells):

```bash
ydotool mousemove -a $(seto -f $'%x %y\n') && ydotool click 0xC0
```

Took a lot of inspirations from [slurp](https://github.com/emersion/slurp) :)
