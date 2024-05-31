{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zls = {
      url = "github:zigtools/zls";
      inputs.zig-overlay.follows = "zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    zig-overlay,
    zls,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = import ./default.nix {inherit pkgs;};
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        zls.packages.${system}.default
        zig
        pango
        cairo
        pkg-config
        wayland
        wayland-scanner
        wayland-protocols
        libxkbcommon
      ];
    };
  };
}
