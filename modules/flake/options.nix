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
          type = types.attrsOf types.anything;
          default = { };
          description = "Hyprland `input` settings merged for this host.";
        };
        settings = mkOption {
          type = types.attrsOf types.anything;
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

      wireguard = {
        profiles = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = "NetworkManager WireGuard profiles for this host (keyfile sections, without key material). Each profile reads its private key from the sops secret `wireguard/<host>/<profile>`; setting `presharedKey = true` on a profile additionally injects `wireguard/<host>/<profile>-psk` into its peer sections. Suffixes listed in `extraSecrets` load `wireguard/<host>/<profile>-<suffix>` as `$WG_<PROFILE>_<SUFFIX>` for referencing in any field.";
        };
      };

      wifi = {
        profiles = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = "NetworkManager Wi-Fi profiles for this host (keyfile sections, without key material). `connection.id` and `wifi.ssid` default to the attribute name. Each profile reads its PSK from the host-independent sops secret `wifi/<profile>`; setting `eap = true` injects the secret as the `802-1x` password instead, and `open = true` skips secrets entirely. Suffixes listed in `extraSecrets` load `wifi/<profile>-<suffix>` as `$WIFI_<PROFILE>_<SUFFIX>` for referencing in any field.";
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
          description = "DMS bar layout for this host. Each entry is merged over the shared bar defaults in dankshell.nix, so hosts usually only set the widget lists.";
        };
        hyprlandOutputSettings = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = "DMS Hyprland Output settings for this host.";
        };
      };
    };
  };
}
