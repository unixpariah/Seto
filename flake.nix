{
  description = "Seto - hardware accelerated keyboard driven screen selection tool";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zls = {
      url = "github:zigtools/zls";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.zig-overlay.follows = "zig";
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
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            libGL
            renderdoc
            pkg-config
            wayland
            wayland-scanner
            wayland-protocols
            wayland-utils
            libxkbcommon
            glxinfo
            freetype
            ydotool
            shfmt
            fontconfig
            clang-tools
            scdoc
            zig.packages.${system}."0.14.0"
            zls.packages.${system}.default
            nixd
            nixfmt-rfc-style
          ];
        };
      });

      packages = forAllSystems (pkgs: {
        default = pkgs.callPackage ./nix/package.nix { };
      });

      homeManagerModules = {
        default = import ./nix/home-manager.nix self;
        stylix = import ./nix/stylix.nix;
      };
    };
}
