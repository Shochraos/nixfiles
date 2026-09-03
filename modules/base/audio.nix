{
  den.aspects.audio.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.host.audio) equalizers;

      safeName = name: builtins.match "[a-zA-Z0-9-]+" name != null;
    in
    {
      assertions = lib.concatLists (
        lib.mapAttrsToList (name: equalizer: [
          {
            assertion = equalizer.presets ? ${equalizer.default};
            message = "host.audio.equalizers.${name}.default is \"${equalizer.default}\", which is not one of its presets (${lib.concatStringsSep ", " (builtins.attrNames equalizer.presets)}).";
          }
          {
            assertion = safeName name && builtins.all safeName (builtins.attrNames equalizer.presets);
            message = "host.audio.equalizers.${name}: the filter name and every preset name must match [a-zA-Z0-9-]+, because both become systemd unit and store path components.";
          }
          {
            assertion = !(equalizer.presets ? "off");
            message = "host.audio.equalizers.${name}: \"off\" is reserved by eq for running no filter at all and cannot be a preset name.";
          }
        ]) equalizers
      );

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;

        extraLadspaPackages = [ pkgs.rnnoise-plugin ];

        extraConfig.pipewire = {
          "99-input-denoising" = {
            "context.modules" = [
              {
                name = "libpipewire-module-filter-chain";
                args = {
                  "node.description" = "RNNoise";
                  "media.name" = "RNNoise";
                  "filter.graph" = {
                    nodes = [
                      {
                        type = "ladspa";
                        name = "rnnoise";
                        plugin = "librnnoise_ladspa";
                        label = "noise_suppressor_mono";
                        control = {
                          "VAD Threshold (%)" = 50.0;
                          "VAD Grace Period (ms)" = 200;
                          "Retroactive VAD Grace (ms)" = 0;
                        };
                      }
                    ];
                  };
                  "capture.props" = {
                    "node.name" = "capture.rnnoise_source";
                    "node.passive" = true;
                    "audio.rate" = 48000;
                    "audio.position" = "[ MONO ]";
                  };
                  "playback.props" = {
                    "node.name" = "rnnoise_source";
                    "media.class" = "Audio/Source";
                    "audio.rate" = 48000;
                    "audio.position" = "[ MONO ]";
                  };
                };
              }
            ];
          };
        };
      };
    };

  den.aspects.audio.provides.to-users.homeManager =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      inherit (osConfig.host.audio) equalizers;

      jsonFormat = pkgs.formats.json { };
      pipewire = lib.getExe' osConfig.services.pipewire.package "pipewire";
      systemctl = lib.getExe' pkgs.systemd "systemctl";

      preampNode = equalizer: {
        type = "builtin";
        name = "preamp";
        label = "bq_lowshelf";
        control = {
          "Freq" = 96000.0;
          "Q" = 0.707;
          "Gain" = equalizer.preamp;
        };
      };

      bandNodes =
        preset:
        lib.imap1 (index: band: {
          type = "builtin";
          name = "eq_band_${toString index}";
          label = band.type;
          control = {
            "Freq" = band.freq;
            "Q" = band.q;
            "Gain" = band.gain;
          };
        }) preset.bands;

      serialLinks =
        nodes:
        lib.zipListsWith (from: to: {
          output = "${from.name}:Out";
          input = "${to.name}:In";
        }) (lib.init nodes) (builtins.tail nodes);

      presetConf =
        name: equalizer: presetName: preset:
        let
          nodes = [ (preampNode equalizer) ] ++ bandNodes preset;
        in
        jsonFormat.generate "pipewire-eq-${name}-${presetName}.conf" {
          "context.spa-libs" = {
            "audio.convert.*" = "audioconvert/libspa-audioconvert";
            "support.*" = "support/libspa-support";
          };
          "context.modules" = [
            {
              name = "libpipewire-module-rt";
              args = { };
              flags = [
                "ifexists"
                "nofail"
              ];
            }
            { name = "libpipewire-module-protocol-native"; }
            { name = "libpipewire-module-client-node"; }
            { name = "libpipewire-module-adapter"; }
            {
              name = "libpipewire-module-filter-chain";
              args = {
                "node.description" = "Equalizer ${name}";
                "media.name" = "Equalizer ${name}";
                "filter.graph" = {
                  inherit nodes;
                  links = serialLinks nodes;
                };
                "audio.channels" = 2;
                "audio.position" = [
                  "FL"
                  "FR"
                ];
                "capture.props" = {
                  "node.name" = "effect_input.${name}";
                  "media.class" = "Audio/Sink";
                  "filter.smart" = true;
                  "filter.smart.name" = name;
                  "filter.smart.target" = equalizer.target;
                };
                "playback.props" = {
                  "node.name" = "effect_output.${name}";
                  "node.passive" = true;
                };
              };
            }
          ];
        };

      presetCases =
        name: equalizer:
        lib.concatStrings (
          lib.mapAttrsToList (presetName: preset: ''
            ${presetName})
              conf=${presetConf name equalizer presetName preset}
              ;;
          '') equalizer.presets
        );

      runner =
        name: equalizer:
        pkgs.writeShellApplication {
          name = "pipewire-eq-${name}";
          runtimeInputs = [ pkgs.coreutils ];
          text = ''
            state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/audio-eq"
            runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$UID}/audio-eq"

            preset=${equalizer.default}
            if [ -r "$state_dir/${name}" ]; then
              read -r preset < "$state_dir/${name}" || preset=${equalizer.default}
            fi

            case "$preset" in
            off)
              printf 'eq: ${name} runs no filter\n' >&2
              exit 0
              ;;
            ${presetCases name equalizer}
            *)
              printf 'eq: ${name} has no preset %s, loading ${equalizer.default}\n' "$preset" >&2
              preset=${equalizer.default}
              conf=${presetConf name equalizer equalizer.default equalizer.presets.${equalizer.default}}
              ;;
            esac

            mkdir -p "$runtime_dir"
            printf '%s\n' "$preset" > "$runtime_dir/${name}"
            printf 'eq: ${name} loading %s\n' "$preset" >&2
            exec ${pipewire} -c "$conf"
          '';
        };

      eq = pkgs.writeShellApplication {
        name = "eq";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          declare -A EQ_PRESETS=(${
            lib.concatStrings (
              lib.mapAttrsToList (
                name: equalizer:
                " [${name}]=${lib.escapeShellArg (lib.concatStringsSep " " (builtins.attrNames equalizer.presets))}"
              ) equalizers
            )
          } )
          devices=(${lib.concatStringsSep " " (builtins.attrNames equalizers)})

          state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/audio-eq"
          runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$UID}/audio-eq"

          die() {
            printf 'eq: %s\n' "$*" >&2
            exit 1
          }

          loaded_preset() {
            local value
            if ! ${systemctl} --user is-active --quiet "pipewire-eq-$1.service"; then
              printf 'off'
              return 0
            fi
            if [ -r "$runtime_dir/$1" ]; then
              read -r value < "$runtime_dir/$1"
              printf '%s' "$value"
            else
              printf 'unknown'
            fi
          }

          selected_preset() {
            local value=""
            if [ -r "$state_dir/$1" ]; then
              read -r value < "$state_dir/$1" || value=""
            fi
            printf '%s' "$value"
          }

          status() {
            local device loaded selected
            for device in "''${devices[@]}"; do
              loaded=$(loaded_preset "$device")
              selected=$(selected_preset "$device")
              printf '%s: %s\n' "$device" "$loaded"
              printf '  presets: %s off\n' "''${EQ_PRESETS[$device]}"
              if [ -n "$selected" ] && [ "$selected" != "$loaded" ]; then
                printf "  warning: '%s' is selected but not loaded; run 'eq %s %s'\n" \
                  "$selected" "$device" "$selected"
              fi
            done
          }

          if (($# == 0)); then
            status
            exit 0
          fi

          case "$1" in
          -h | --help)
            printf 'usage: eq                          report the loaded preset\n'
            printf '       eq [<device>] <preset|off>  load a preset, or no filter at all\n'
            exit 0
            ;;
          esac

          if (($# == 1)); then
            if ((''${#devices[@]} != 1)); then
              die "more than one equalizer (''${devices[*]}); name one: eq <device> <preset>"
            fi
            device=''${devices[0]}
            preset=$1
          elif (($# == 2)); then
            device=$1
            preset=$2
          else
            die "usage: eq [<device>] <preset|off>"
          fi

          [ -n "''${EQ_PRESETS[$device]:-}" ] || die "unknown equalizer '$device'; known: ''${devices[*]}"

          if [ "$preset" != off ]; then
            read -ra known <<<"''${EQ_PRESETS[$device]}"
            found=0
            for candidate in "''${known[@]}"; do
              if [ "$candidate" = "$preset" ]; then
                found=1
              fi
            done
            ((found)) || die "'$device' has no preset '$preset'; known: ''${EQ_PRESETS[$device]} off"
          fi

          mkdir -p "$state_dir"
          printf '%s\n' "$preset" > "$state_dir/$device"

          if [ "$preset" = off ]; then
            ${systemctl} --user stop "pipewire-eq-$device.service"
          else
            ${systemctl} --user restart "pipewire-eq-$device.service"
          fi
          printf '%s: %s\n' "$device" "$preset"
        '';
      };
    in
    {
      home.packages = lib.optional (equalizers != { }) eq;

      systemd.user.services = lib.mapAttrs' (
        name: equalizer:
        lib.nameValuePair "pipewire-eq-${name}" {
          Unit = {
            Description = "Playback equalizer ${name}";
            Requires = [ "pipewire.service" ];
            After = [ "pipewire.service" ];
            PartOf = [ "pipewire.service" ];
          };

          Service = {
            Type = "simple";
            ExecStart = lib.getExe (runner name equalizer);
            Restart = "on-failure";
            RestartSec = 2;
          };

          Install = {
            WantedBy = [ "pipewire.service" ];
          };
        }
      ) equalizers;
    };
}
