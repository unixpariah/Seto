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
            zig.packages.${system}."0.13.0"
            zls.packages.${system}.default
            nixd
            nixfmt-rfc-style
            #(callPackage ./nix/dawn.nix { })
          ];
        };
      });

      packages = forAllSystems (pkgs: rec {
        default = safe;
        safe = pkgs.callPackage ./nix/package.nix { build = "ReleaseSafe"; };
        debug = pkgs.callPackage ./nix/package.nix { build = "Debug"; };
        fast = pkgs.callPackage ./nix/package.nix { build = "ReleaseFast"; };
        small = pkgs.callPackage ./nix/package.nix { build = "ReleaseSmall"; };
      });

      homeManagerModules = {
        default = import ./nix/home-manager.nix self;
        stylix = import ./nix/stylix.nix;
      };
    };
}
