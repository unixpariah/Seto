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
    env = zig2nix.outputs.zig-env.${system} {zig = zig2nix.outputs.packages.${system}.zig."0.12.0".bin;};
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
              libxkbcommon
            ];

            buildInputs = with env.pkgsForTarget target; [
              pkg-config
              scdoc
            ];

            zigPreferMusl = true;

            zigDisableWrap = true;

            installPhase = ''
              mkdir -p $out/bin
              cp zig-out/bin/seto $out/bin
            '';

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
          }
          // optionalAttrs (!pathExists ./build.zig.zon) {
            pname = "seto";
            version = "0.1.0";
          }));

      # nix build .
      packages.default = packages.target.${system-triple}.override {
        zigPreferMusl = false;
        zigDisableWrap = false;
      };

      apps.bundle.target = genAttrs allTargetTriples (target: let
        pkg = packages.target.${target};
      in {
        type = "app";
        program = "${pkg}/bin/default";
      });

      # default bundle
      apps.bundle.default = apps.bundle.target.${system-triple};

      # nix run .#zon2json-lock
      apps.zon2json-lock = env.app [env.zon2json-lock] "zon2json-lock \"$@\"";

      # nix develop
      devShells.default = env.mkShell {
        packages = with env.pkgs; [
          pango
          cairo
          pkg-config
          wayland
          wayland-protocols
          libxkbcommon
          zls.packages.${system}.default
        ];
      };
    }));
}
