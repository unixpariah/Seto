{
  lib,
  stdenv,
  freetype,
  fontconfig,
  libGL,
  wayland,
  wayland-scanner,
  wayland-protocols,
  libxkbcommon,
  zig,
  pkg-config,
  scdoc,
  installShellFiles,
  callPackage,
  lua,
  arrayLength ? 100,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "seto";
  version = "0.1.0";

  src = ./..;

  dontConfigure = true;
  doCheck = false;

  nativeBuildInputs = [
    zig.hook
    wayland-scanner
    pkg-config
    scdoc
    installShellFiles
    wayland-protocols
  ];

  buildInputs = [
    wayland
    libGL
    libxkbcommon
    freetype
    fontconfig
    lua
  ];

  zigBuildFlags = [ "--release=safe" ];

  postPatch = ''
    ln -s ${callPackage ./deps.nix { }} $ZIG_GLOBAL_CACHE_DIR/p
  '';

  postInstall = ''
    for f in doc/*.scd; do
      local page="doc/$(basename "$f" .scd)"
      scdoc < "$f" > "$page"
      installManPage "$page"
    done

    installShellCompletion --cmd seto \
      --bash completions/seto.bash \
      --fish completions/seto.fish \
      --zsh completions/_seto
  '';

  meta = with lib; {
    description = "Hardware accelerated keyboard driven screen selection tool";
    mainProgram = "seto";
    homepage = "https://github.com/unixpariah/seto";
    license = licenses.gpl3;
    maintainers = with maintainers; [ unixpariah ];
    platforms = platforms.linux;
  };
})
