{ lib, ... }:
let
  inherit (lib) mkOption types;
  anyList = types.listOf types.anything;
in
{
  aspects.nixos.hostOptions = {
    options.host = {
      hyprland = {
        input = mkOption {
          type = types.attrs;
          default = { };
          description = "Hyprland `input` settings merged for this host.";
        };
        settings = mkOption {
          type = types.attrs;
          default = { };
          description = "Hyprland top-level config settings for this host.";
        };
        gestures = mkOption {
          type = anyList;
          default = [ ];
          description = "Hyprland `gesture` entries for this host.";
        };
        workspaceRules = mkOption {
          type = anyList;
          default = [ ];
          description = "Hyprland `workspace_rule` entries for this host.";
        };
        windowRules = mkOption {
          type = anyList;
          default = [ ];
          description = "Hyprland `window_rule` entries for this host.";
        };
        keybinds = mkOption {
          type = anyList;
          default = [ ];
          description = "Hyprland `bind` entries (from host + feature modules).";
        };
      };

      dms = {
        powerMenuActions = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "DMS power-menu actions for this host.";
        };
        barConfigs = mkOption {
          type = anyList;
          default = [ ];
          description = "DMS bar layout for this host.";
        };
        hyprlandOutputSettings = mkOption {
          type = types.attrs;
          default = { };
          description = "DMS Hyprland Output settings for this host.";
        };
      };
    };
  };
}
