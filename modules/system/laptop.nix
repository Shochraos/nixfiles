{
  den.aspects.laptop.nixos = {
    services.power-profiles-daemon.enable = true;
    services.scx.extraArgs = [ "--autopower" ];

    services.upower.enable = true;
    services.fwupd.enable = true;

    systemd.network.wait-online.enable = false;

    hardware.alsa.enablePersistence = true;
  };
}
