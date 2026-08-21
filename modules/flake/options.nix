{ den, lib, ... }:
let
  inherit (lib) mkOption types;
  openAttrs = types.attrsOf types.anything;
  attrsetList = types.listOf openAttrs;
  attrsetTable = types.attrsOf openAttrs;
in
{
  den.default.includes = [ den.aspects.hostOptions ];

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
                    primary = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Output is this host's primary display. At most one entry may set it. Consumed by dankshell, which pins the bar to it; with no primary the bar spans every output.";
                    };
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
                    mode = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = "Resolution and refresh rate as Hyprland spells it, e.g. `3840x2160@143.988`. Null leaves the field to whatever DMS last wrote.";
                    };
                    position = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = "Logical position of this output's top-left corner, e.g. `220x1798`. Null leaves the field to whatever DMS last wrote.";
                    };
                    scale = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = "Fractional scale as a string, e.g. `0.80078125`. Hyprland snaps a scale that does not divide the mode into whole logical pixels, so use the value it reports rather than the one you asked for. Null leaves the field to whatever DMS last wrote.";
                    };
                    workspaces = mkOption {
                      type = types.listOf types.ints.positive;
                      default = [ ];
                      description = "Workspaces that live on this output. Each becomes a persistent `workspace_rule` bound to it, which is what makes the monitor-relative `m+1`/`m-1` cycle wrap within this output alone. The first entry is that output's default workspace.";
                    };
                  };
                }
              );
              description = "Physical outputs of this host, keyed by Hyprland output name. Consumed by dankshell (which derives the DMS output settings), by the hdr aspect (which drives the single entry with `hdr = true`) and by the hyprland aspect (which pins the geometry Hyprland cannot be told through DMS, and binds each output's workspaces to it).";
            };

            audio = {
              equalizers = mkOption {
                default = { };
                type = types.attrsOf (
                  types.submodule {
                    options = {
                      target = mkOption {
                        type = types.attrsOf types.str;
                        description = "WirePlumber smart-filter match rules. Every key must equal the property of the same name on the target node, so `api.alsa.card.name` survives an ALSA profile change that would rename `node.name`.";
                      };
                      preamp = mkOption {
                        type = types.number;
                        default = 0.0;
                        description = "Broadband gain in dB applied ahead of the bands, sized against the largest positive band gain so boosts cannot clip. Emitted as a `bq_lowshelf` above Nyquist, which the biquad collapses to a constant gain.";
                      };
                      bands = mkOption {
                        type = types.listOf (
                          types.submodule {
                            options = {
                              type = mkOption {
                                type = types.enum [
                                  "bq_lowshelf"
                                  "bq_peaking"
                                  "bq_highshelf"
                                  "bq_lowpass"
                                  "bq_highpass"
                                  "bq_bandpass"
                                  "bq_notch"
                                  "bq_allpass"
                                ];
                                description = "Builtin biquad label for this band.";
                              };
                              freq = mkOption {
                                type = types.number;
                                description = "Centre or corner frequency in Hz.";
                              };
                              gain = mkOption {
                                type = types.number;
                                default = 0.0;
                                description = "Band gain in dB.";
                              };
                              q = mkOption {
                                type = types.number;
                                default = 0.707;
                                description = "Band Q.";
                              };
                            };
                          }
                        );
                        default = [ ];
                        description = "Bands applied in series, each emitted as its own biquad node named `eq_band_<n>` so its Freq, Q and Gain stay live-settable with `pw-cli set-param <capture node> Props`.";
                      };
                    };
                  }
                );
                description = "Playback equalizers for this host, keyed by filter name. Each entry becomes a PipeWire filter-chain that WirePlumber inserts in front of the matched device, so every stream reaching that device is equalised without the filter ever becoming a default sink.";
              };
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

            matugen = {
              templates = mkOption {
                type = attrsetTable;
                default = { };
                description = "matugen templates contributed by feature aspects, merged over the shared template set in the hyprland theme aspect. Lets a feature theme itself from the live palette without depending on the hyprland aspect being present.";
              };
            };
          };
        };
    };
}
