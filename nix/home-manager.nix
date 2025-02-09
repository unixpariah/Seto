self:
{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.seto;
in
{
  options.programs.seto = {
    enable = mkEnableOption "seto, hardware accelerated screen selection tool";
    package = lib.mkPackageOption pkgs "seto" { };
    settings = {
      background_color = mkOption {
        type = types.str;
        default = "#FFFFFF66";
        description = "Background color in hex. Supports a single color or a gradient with two colors and an angle. Hashtag alpha channel and angle can be omitted.";
        example = "#FFFFFF66 #00FF0066 45deg";
      };
      font = {
        family = mkOption {
          type = types.str;
          default = "monospace";
          description = "Font family";
          example = "monospace";
        };
        size = mkOption {
          type = types.str;
          default = "20";
          description = "Font size";
          example = "8";
        };
        color = mkOption {
          type = types.str;
          default = "#FFFFFF";
          description = "Font color in hex. Supports a single color or a gradient with two colors and an angle. Hashtag alpha channel and angle can be omitted.";
          example = "#FF5733 #C70039 90deg";
        };
        highlight_color = mkOption {
          type = types.str;
          default = "#FFFF00";
          description = "Highlight color for font in hex. Supports a single color or a gradient with two colors and an angle.";
          example = "#FF5733 #C70039 90deg";
        };
      };
      grid = {
        color = mkOption {
          type = types.str;
          default = "#FFFFFF";
          description = "Grid color in hex. Supports a single color or a gradient with two colors and an angle. Hashtag alpha channel and angle can be omitted.";
          example = "#3498DB #2ECC71 135deg";
        };
        size = mkOption {
          type = types.listOf types.int;
          default = [
            80
            80
          ];
          description = "Width and height of each square in grid";
          example = [
            60
            60
          ];
        };
        selected_color = mkOption {
          type = types.str;
          default = "#FF0000";
          description = "Selected grid color in hex. Supports a single color or a gradient with two colors and an angle. Hashtag alpha channel and angle can be omitted.";
          example = "#8E44AD #F1C40F 60deg";
        };
      };
      keys = {
        search = mkOption {
          type = types.str;
          default = "asdfghjkl";
          description = "Keys used for selecting grid";
          example = "asdfghjkl";
        };
        bindings = mkOption {
          type = types.attrsOf (
            types.either types.str (
              types.submodule {
                options = {
                  move = mkOption {
                    type = types.listOf types.int;
                    default = [ ];
                    description = "Move offset in pixels [x, y]";
                    example = [
                      80
                      80
                    ];
                  };
                  resize = mkOption {
                    type = types.listOf types.int;
                    default = [ ];
                    description = "Resize amount in pixels [width, height]";
                    example = [
                      80
                      80
                    ];
                  };
                  move_selection = mkOption {
                    type = types.listOf types.int;
                    default = [ ];
                    description = "Selection movement offset in pixels [x, y]";
                    example = [
                      80
                      80
                    ];
                  };
                };
              }
            )
          );
          default = { };
          description = "Custom key bindings, each can be a function with arguments or a simple string";
          example = literalExpression ''{ "z" = { move = [ -5 0 ]; }; }'';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."seto/config.lua".text = ''
      return {
        background_color = "${cfg.settings.background_color}";
        font = {
          color = "${cfg.settings.font.color}",
          size = "${cfg.settings.font.size}",
          highlight_color = "${cfg.settings.font.highlight_color}",
          family = "${cfg.settings.font.family}",
        },
        grid = {
          color = "${cfg.settings.grid.color}",
          size = { ${concatStringsSep ", " (map toString cfg.settings.grid.size)} },
          selected_color = "${cfg.settings.grid.selected_color}",
        },
        keys = {
          search = "${cfg.settings.keys.search}",
          bindings = {
            ${lib.concatStringsSep "\n      " (
              mapAttrsToList (
                key: val:
                if builtins.isString val then
                  ''${key} = "${val}",''
                else
                  let
                    definedAttrs = filterAttrs (n: v: v != [ ]) val;
                    attrName = head (attrNames definedAttrs);
                  in
                  ''${key} = { ${attrName} = { ${
                    lib.concatStringsSep ", " (map toString definedAttrs.${attrName})
                  } }, },''
              ) cfg.settings.keys.bindings
            )}
          },
        },
      }
    '';
  };
}
