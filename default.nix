{pkgs ? import <nixpkgs> {}}:
pkgs.stdenv.mkDerivation {
  name = "seto";
  src = ./.;

  buildInputs = with pkgs; [
    zig
    cairo
    wayland
    libxkbcommon
  ];

  nativeBuildInputs = with pkgs; [
    pkg-config
    wayland-protocols
    wayland-scanner
  ];

  buildPhase = ''
    XDG_CACHE_HOME=xdg_cache zig build -Doptimize=ReleaseFast
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp zig-out/bin/seto $out/bin
  '';
}
