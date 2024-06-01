{pkgs}: let
  grim = "${pkgs.grim}/bin/grim";
in
  pkgs.writeShellScriptBin "screenshot" ''
    ${grim} -g "$(../zig-out/bin/seto -r)" - | wl-copy -t image/png
  ''
