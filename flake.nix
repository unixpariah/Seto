{
  description = "Keyboard based screen selection tool";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
        zigEnv = pkgs.mkShell {
          buildInputs = with pkgs; [
            zig
            zls
            pkg-config
            wayland
            wayland-protocols
            wayland-utils
            wayland-scanner
            wlroots
          ];
        };
      in {
        devShell = zigEnv;
        packages = {
          sip = pkgs.stdenv.mkDerivation {
            name = "sip";
            src = ./.;
            buildInputs = with pkgs; [zig];
            buildPhase = ''
              zig build
            '';
            installPhase = ''
              mkdir -p $out/bin
              cp zig-out/bin/waystatus $out/bin/
            '';
          };
        };
      }
    );
}
