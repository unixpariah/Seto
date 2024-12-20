{ config, ... }:
with config.lib.stylix.colors.withHashtag;
with config.stylix.fonts;
{
  lib,
  config,
  ...
}:
{
  options.stylix.targets.seto.enable = config.lib.stylix.mkEnableTarget "seto" true;

  config = lib.mkIf (config.stylix.enable && config.stylix.targets.seto.enable) {
    programs.seto = {
      backgroundColor = base00;
      font = {
        family = sansSerif.name;
        size = "${toString sizes.popups}";
        color = base05;
        highlightColor = base04;
      };
      grid = {
        color = base0D;
        selectedColor = base02;
      };
    };
  };
}
