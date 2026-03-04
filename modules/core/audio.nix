{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ rnnoise-plugin ];
  
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = 
  {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    
    extraConfig.pipewire."99-input-denoising" = 
    {
      "context.modules" = 
      [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "RNNoise";
            "media.name" = "RNNoise";
            "filter.graph" = 
            {
              nodes = 
              [
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                  label = "noise_suppressor_mono";
                  control = 
                  {
                    "VAD Threshold (%)" = 50.0;
                    "VAD Grace Period (ms)" = 200;
                    "Retroactive VAD Grace (ms)" = 0;
                  };
                }
              ];
            };
            "capture.props" = 
            {
              "node.name" = "capture.rnnoise_source";
              "node.passive" = true;
              "audio.rate" = 48000;
     	        "audio.position" = "[ MONO ]";
            };
            "playback.props" = 
            {
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
}