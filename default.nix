{ lib, stdenv, freetype, fontconfig, libGL, wayland, wayland-scanner
, wayland-protocols, libxkbcommon, zig_0_13, pkg-config, scdoc
, installShellFiles, callPackage, }:
stdenv.mkDerivation (finalAttrs: {
  pname = "seto";
  version = "0.1.0";

  src = ./.;

  dontConfigure = true;
  doCheck = false;

  nativeBuildInputs = [
    zig_0_13
    wayland
    wayland-protocols
    libGL
    libxkbcommon
    freetype
    fontconfig
  ];

  buildInputs = [ pkg-config scdoc installShellFiles wayland-scanner ];

  buildPhase = ''
    mkdir -p .cache
    ln -s ${callPackage ./deps.nix { }} .cache/p
    zig build install --cache-dir $(pwd)/.zig-cache --global-cache-dir $(pwd)/.cache -Dcpu=baseline -Doptimize=ReleaseSafe --prefix $out
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

  meta = with lib; {
    description = "Hardware accelerated keyboard driven screen selection tool";
    mainProgram = "seto";
    homepage = "https://github.com/unixpariah/seto";
    license = licenses.mit;
    maintainers = with maintainers; [ unixpariah ];
    platforms = platforms.unix;
  };
})
