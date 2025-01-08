{
  lib,
  config,
  ...
}:
with config.lib.stylix.colors.withHashtag;
with config.stylix.fonts;
{
  options.stylix.targets.seto.enable = config.lib.stylix.mkEnableTarget "seto" true;

  config = lib.mkIf (config.stylix.enable && config.stylix.targets.seto.enable) {
    programs.seto.settings = {
      background_color = base00 + "66";
      font = {
        family = sansSerif.name;
        color = base05;
        highlight_color = base04;
      };
      grid = {
        color = base0D;
        selected_color = base02;
      };
    };
  };
}
