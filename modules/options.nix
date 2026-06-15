# Typed slots for host-specific layout/capability data. Shared modules (hypr,
# dms) *consume* these; hosts and feature modules *populate* them. This replaces
# the former `config.modules.<host>.isLoaded or false` host-identity coupling.
# list-typed slots concatenate across all definitions, so several producers can
# contribute (e.g. host + gamechat + lgtv all add keybinds).
{ lib, ... }:
let
  inherit (lib) mkOption types;
  anyList = types.listOf types.anything;
in
{
  aspects.nixos.hostOptions = {
    options.host = {
      hyprland = {
        inputExtra = mkOption {
          type = types.attrs;
          default = { };
          description = "Extra Hyprland `input` settings merged for this host.";
        };
        settingsExtra = mkOption {
          type = types.attrs;
          default = { };
          description = "Extra top-level Hyprland config settings for this host.";
        };
        gestures = mkOption {
          type = anyList;
          default = [ ];
          description = "Hyprland `gesture` entries for this host.";
        };
        workspaceRules = mkOption {
          type = anyList;
          default = [ ];
          description = "Extra Hyprland `workspace_rule` entries for this host.";
        };
        windowRules = mkOption {
          type = anyList;
          default = [ ];
          description = "Extra Hyprland `window_rule` entries for this host.";
        };
        keybinds = mkOption {
          type = anyList;
          default = [ ];
          description = "Extra Hyprland `bind` entries (from host + feature modules).";
        };
      };

      dms = {
        powerMenuExtraActions = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Extra DMS power-menu actions for this host.";
        };
        barConfigs = mkOption {
          type = anyList;
          default = [ ];
          description = "DMS bar layout for this host.";
        };
        hyprlandOutputSettings = mkOption {
          type = types.attrs;
          default = { };
          description = "Per-output DMS Hyprland settings for this host.";
        };
      };
    };
  };
}
