{
  description = "Seto - hardware accelerated keyboard driven screen selection tool";

  inputs = {
    lato.url = "github:unixpariah/liblato";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zls.url = "github:zigtools/zls";
    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    zls,
    flake-utils,
    zig,
    lato,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        devShell = pkgs.mkShell {
          packages = with pkgs; [
            pkg-config
            wayland
            wayland-protocols
            wayland-utils
            libxkbcommon
            libGL
            glxinfo
            freetype
            ydotool
            shfmt
            fontconfig
            clang-tools
            scdoc
            lato.packages.${system}.default
            zls.packages.${system}.default
            zig.packages.${system}."0.13.0"
          ];
        };

        packages.default = pkgs.callPackage ./default.nix {
          #lato = lato.packages.${system}.default;
        };
      }
    );
}
