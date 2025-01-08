self:
{ lib, config, ... }:
with lib;
let
  cfg = config.programs.seto;
in
{
  options.programs.seto = {
    enable = mkEnableOption "seto, hardware accelerated screen selection tool";
    package = mkOption {
      type = types.package;
      default =
        self.packages.${pkgs.system}.seto or (throw ''
          The seto package is not available for your system. Please make sure it's available in your flake's packages output for ${pkgs.system}.
        '');
      defaultText = literalExpression "self.packages.\${pkgs.system}.seto";
      description = "The seto package to use. Must be available in your flake's packages output.";
    };
    wlrPortalChooser = mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    xdg.portal.wlr = {
      enable = true;
      settings = {
        screencast = {
          chooser_cmd = "${cfg.package}/bin/seto -f %o";
          chooser_type = "simple";
        };
      };
    };
  };
}
