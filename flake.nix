{
  description = "Seto - hardware accelerated keyboard driven screen selection tool";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zls = {
      url = "github:zigtools/zls";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      zig,
      zls,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        function: nixpkgs.lib.genAttrs systems (system: function nixpkgs.legacyPackages.${system});

      stylix-module = import ./nix/stylix.nix;
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
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
      });
      packages = forAllSystems (pkgs: {
        default = pkgs.callPackage ./nix/default.nix { };
      });

      # Expose both modules
      homeManagerModules = {
        default = import ./nix/home-manager.nix self;
        stylix = stylix-module;
      };
    };
}
