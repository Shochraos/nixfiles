{ pkgs, username, ... }:
{
  services.upower.enable = true;
  services.fwupd.enable = true;

  systemd.network.wait-online.enable = false;

  hardware.alsa.enablePersistence = true;

  home-manager.users.${username} = {
    home.packages = with pkgs; [
      pdfpc
    ];
  };
}
