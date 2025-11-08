{ config, pkgs, ... }: {

  # Pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    #Pulseaudio compatbility layer
    pulse.enable = true;
  };
}