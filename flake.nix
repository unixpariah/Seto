{
  description = "Seto - keyboard based screen selection tool";

  inputs = {
    zig2nix.url = "github:Cloudef/zig2nix";
    zls.url = "github:zigtools/zls";
  };

  outputs = {
    zig2nix,
    zls,
    ...
  }: let
    flake-utils = zig2nix.inputs.flake-utils;
  in (flake-utils.lib.eachDefaultSystem (system: let
    env = zig2nix.outputs.zig-env.${system} {zig = zig2nix.outputs.packages.${system}.zig."0.13.0".bin;};
    system-triple = env.lib.zigTripleFromString system;
  in
    with builtins;
    with env.lib;
    with env.pkgs.lib; rec {
      packages.target = genAttrs allTargetTriples (target:
        env.packageForTarget target ({
            src = cleanSource ./.;

            nativeBuildInputs = with env.pkgs; [
              pango
              cairo
              wayland
              wayland-protocols
              egl-wayland
              libGl
              libxkbcommon
            ];

            buildInputs = with env.pkgsForTarget target; [
              pkg-config
              scdoc
              installShellFiles
            ];

            zigPreferMusl = true;

            zigDisableWrap = true;
          }
          // optionalAttrs (!pathExists ./build.zig.zon) {
            pname = "seto";
            version = "0.1.0";
          }));

      # nix build .
      packages.default = packages.target.${system-triple}.override {
        zigPreferMusl = false;
        zigDisableWrap = false;

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
      };

      apps.bundle.target = genAttrs allTargetTriples (target: let
        pkg = packages.target.${target};
      in {
        type = "app";
        program = "${pkg}/bin/default";
      });

      apps.bundle.default = apps.bundle.target.${system-triple};

      # nix run .#zon2json-lock
      apps.zon2json-lock = env.app [env.zon2json-lock] "zon2json-lock \"$@\"";

      devShells.default = env.mkShell {
        packages = with env.pkgs; [
          pango
          cairo
          pkg-config
          wayland
          wayland-protocols
          wayland-scanner
          libxkbcommon
          egl-wayland
          libGL
          zls.packages.${system}.default
        ];
      };
    }));
}
