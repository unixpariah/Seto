{
  description =
    "Seto - hardware accelerated keyboard driven screen selection tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zls.url = "github:zigtools/zls";
    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, zig, zls, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          pkg-config
          wayland
          wayland-scanner
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
          zls.packages.${system}.default
          zig.packages.${system}."0.13.0"
        ];
      };

      packages.${system}.default = pkgs.callPackage ./nix/default.nix { };
      homeManagerModules.default = import ./nix/home-manager.nix;
    };
}
