self:
{ pkgs, config, lib, ... }:
with lib;
let cfg = config.home.seto;
in {
  options.home.seto = {
    enable = mkEnableOption "seto, hardware accelerated screen selection tool";

    extraConfig = mkOption {
      type = types.lines;
      default = "return {};";
      example = literalExpression "";
      description = "";
    };

    package = mkPackageOption pkgs "seto" { };
  };

  config = {
    home.packages = [ cfg.package ];

    xdg.configFile."seto/config.lua".text = "${cfg.extraConfig}";
  };
}
