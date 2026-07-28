{ lib, ... }:
let
  inherit (lib) mkOption types;
  openAttrs = types.attrsOf types.anything;
  attrsetList = types.listOf openAttrs;
  attrsetTable = types.attrsOf openAttrs;
in
{
  den.aspects.hostOptions =
    { host, user, ... }:
    {
      nixos =
        { config, ... }:
        {
          options.host = {
            flakeDir = mkOption {
              type = types.str;
              description = "Absolute path to this flake's checkout on the host.";
            };

            sshKey = mkOption {
              type = types.str;
              default = "${config.users.users.${user.name}.home}/.ssh/${lib.toLower host.name}";
              description = "Private SSH key identifying this host. Doubles as the sops age identity and as the default identity for outbound SSH.";
            };

            outputs = mkOption {
              default = { };
              type = types.attrsOf (
                types.submodule {
                  options = {
                    hdr = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Output is HDR-capable. Advertised to DMS as `supportsHdr` and used as the target of `hdr-set`.";
                    };
                    wideColor = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Output covers a wide colour gamut. Advertised to DMS as `supportsWideColor`.";
                    };
                    vrrFullscreenOnly = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Restrict variable refresh rate to fullscreen surfaces.";
                    };
                    bitdepth = mkOption {
                      type = types.nullOr (
                        types.enum [
                          8
                          10
                        ]
                      );
                      default = null;
                      description = "Colour depth per channel. Null leaves the compositor default.";
                    };
                  };
                }
              );
              description = "Physical outputs of this host, keyed by Hyprland output name. Consumed by dankshell (which derives the DMS output settings) and by the hdr aspect (which drives the single entry with `hdr = true`).";
            };

            hyprland = {
              input = mkOption {
                type = openAttrs;
                default = { };
                description = "Hyprland `input` settings merged for this host.";
              };
              settings = mkOption {
                type = openAttrs;
                default = { };
                description = "Hyprland top-level config settings for this host.";
              };
              gestures = mkOption {
                type = attrsetList;
                default = [ ];
                description = "Hyprland `gesture` entries for this host.";
              };
              workspaceRules = mkOption {
                type = attrsetList;
                default = [ ];
                description = "Hyprland `workspace_rule` entries for this host.";
              };
              windowRules = mkOption {
                type = attrsetList;
                default = [ ];
                description = "Hyprland `window_rule` entries for this host.";
              };
              keybinds = mkOption {
                type = attrsetList;
                default = [ ];
                description = "Hyprland `bind` entries (from host + feature modules).";
              };
            };

            wireguard = {
              profiles = mkOption {
                type = attrsetTable;
                default = { };
                description = "NetworkManager WireGuard profiles for this host (keyfile sections, without key material). Each profile reads its private key from the sops secret `wireguard/<host>/<profile>`; setting `presharedKey = true` on a profile additionally injects `wireguard/<host>/<profile>-psk` into its peer sections. Suffixes listed in `extraSecrets` load `wireguard/<host>/<profile>-<suffix>` as `$WG_<PROFILE>_<SUFFIX>` for referencing in any field.";
              };
            };

            wifi = {
              profiles = mkOption {
                type = attrsetTable;
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
                type = attrsetList;
                default = [ ];
                description = "DMS bar layout for this host. Each entry is merged over the shared bar defaults in dankshell.nix, so hosts usually only set the widget lists.";
              };
              plugins = mkOption {
                type = attrsetTable;
                default = { };
                description = "DMS plugins contributed by feature aspects, merged over the shared plugin set in dankshell.nix. Lets a feature enable its own plugin without depending on the dankshell aspect being present.";
              };
            };
          };
        };
    };
}
