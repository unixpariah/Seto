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
    backgroundColor = mkOption {
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
      color = mkOption {
        type = types.str;
        default = "#FFFFFF";
        description = "Font color in hex. Supports a single color or a gradient with two colors and an angle. Hashtag alpha channel and angle can be omitted.";
        example = "#FF5733 #C70039 90deg";
      };
      highlightColor = mkOption {
        type = types.str;
        default = "#FFFF00";
        description = "Highlight color for font";
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
      selectedColor = mkOption {
        type = types.str;
        default = "FF0000";
        description = "Selected grid color in hex. Supports a single color or a gradient with two colors and an angle. Hashtag alpha channel and angle can be omitted.";
        example = "#8E44AD #F1C40F 60deg";
      };
    };
    keys = {
      search = mkOption {
        type = types.str;
        default = "asdfghjkl";
        description = "Keys used to selecting grid";
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
                  description = "Width and height of each square in grid";
                  example = [
                    80
                    80
                  ];
                };
                resize = mkOption {
                  type = types.listOf types.int;
                  default = [ ];
                  description = "Width and height of each square in grid";
                  example = [
                    80
                    80
                  ];
                };
                move_selection = mkOption {
                  type = types.listOf types.int;
                  default = [ ];
                  description = "Width and height of each square in grid";
                  example = [
                    80
                    80
                  ];
                };
              };
            }
          )
        );
        default = {
          z.move = [
            (-5)
            0
          ];
          x.move = [
            0
            (-5)
          ];
          n.move = [
            0
            5
          ];
          m.move = [
            5
            0
          ];
          Z.resize = [
            (-5)
            0
          ];
          X.resize = [
            0
            5
          ];
          N.resize = [
            0
            (-5)
          ];
          M.resize = [
            5
            0
          ];
          H.move_selection = [
            (-5)
            0
          ];
          J.move_selection = [
            0
            5
          ];
          K.move_selection = [
            0
            (-5)
          ];
          L.move_selection = [
            5
            0
          ];
          c = "cancel_selection";
          o = "border_mode";
        };
        description = "Custom key bindings, each can be a function with arguments or a simple string.";
        example = literalExpression "z = { move = { -5, 0 } }";
      };
    };

    package = mkPackageOption pkgs "seto" { };
  };

  config = {
    home.packages = [ cfg.package ];

    xdg.configFile."seto/config.lua".text = ''
            return {
                background_color = "${cfg.backgroundColor}";
                font = {
                    color = "${cfg.font.color}",
                    highlight_color = "${cfg.font.highlightColor}",
                    family = "${cfg.font.family}",
                },
                grid = {
                    color = "${cfg.grid.color}",
                    size = { ${concatStringsSep ", " (map toString cfg.grid.size)} },
                    selected_color = "${cfg.grid.selectedColor}",
                },
                keys = {
                  search = "${cfg.keys.search}",
                  bindings = { ${
                    lib.concatStringsSep "\n" (
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
                      ) cfg.keys.bindings
                    )
                  }
      		  },
                },
            }
    '';
  };
}
