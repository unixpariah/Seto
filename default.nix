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
    XDG_CACHE_HOME="xdg_cache" zig build -Doptimize=ReleaseFast
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp zig-out/bin/seto $out/bin
  '';

  postInstall = ''
    for f in doc/*.scd; do
      local page="doc/$(basename "$f" .scd)"
      scdoc < "$f" > "$page"
      installManPage "$page"
    done

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
