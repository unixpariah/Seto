{pkgs ? import <nixpkgs> {}}:
pkgs.stdenv.mkDerivation {
  name = "seto";
  src = ./.;

  buildInputs = with pkgs; [
    zig
    cairo
    pango
    wayland
    libxkbcommon
  ];

  doCheck = false;

  nativeBuildInputs = with pkgs; [
    pkg-config
    wayland-protocols
    installShellFiles
    wayland-scanner
  ];

  buildPhase = ''
    zig build -Doptimize=ReleaseFast
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp zig-out/bin/seto $out/bin
  '';

  postInstall = ''
    installShellCompletion --cmd sww \
      --bash completions/seto.bash \
      --fish completions/seto.fish \
      --zsh completions/_seto
  '';

  meta = {
    description = "Keyboard based screen selection tool for wayland";
    mainProgram = "seto";
  };
}
