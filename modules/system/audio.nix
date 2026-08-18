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
        equalizer:
        lib.imap1 (index: band: {
          type = "builtin";
          name = "eq_band_${toString index}";
          label = band.type;
          control = {
            "Freq" = band.freq;
            "Q" = band.q;
            "Gain" = band.gain;
          };
        }) equalizer.bands;

      serialLinks =
        nodes:
        lib.zipListsWith (from: to: {
          output = "${from.name}:Out";
          input = "${to.name}:In";
        }) (lib.init nodes) (builtins.tail nodes);

      equalizerConfig =
        name: equalizer:
        let
          nodes = [ (preampNode equalizer) ] ++ bandNodes equalizer;
        in
        {
          "context.modules" = [
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

      equalizerConfigs = lib.mapAttrs' (
        name: equalizer: lib.nameValuePair "99-output-eq-${name}" (equalizerConfig name equalizer)
      ) equalizers;
    in
    {
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
        }
        // equalizerConfigs;
      };
    };
}
