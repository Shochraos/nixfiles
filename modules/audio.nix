{ pkgs, ... }:
{
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

  # Manually add Pulseaudio to have access to pactl
  environment.systemPackages = with pkgs;
  [
    pulseaudio
  ];
}