{ pkgs, lib, rustPlatform, cargo, rustc, rust-analyzer-unwrapped, pkg-config
, wayland, vulkan-loader }:
let cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
in rustPlatform.buildRustPackage {
  pname = "status-bar";
  version = "${cargoToml.package.version}";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.intersection
      (lib.fileset.fromSource (lib.sources.cleanSource ./.))
      (lib.fileset.unions [ ./src ./Cargo.toml ./Cargo.lock ]);
  };

  strictDeps = true;

  buildInputs = [ ];

  nativeBuildInputs =
    [ cargo rustc rust-analyzer-unwrapped pkg-config wayland vulkan-loader ];

  configurePhase = ''
    export PKG_CONFIG_PATH=${pkgs.wayland.dev}/lib/pkgconfig
  '';

  doCheck = false;

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Hardware accelerated status bar";
    homepage = "https://github.com/unixpariah/status-bar";
    license = lib.licenses.gpl3;
    mainProgram = "status-bar";
    maintainers = with lib.maintainers; [ unixpariah ];
  };
}
