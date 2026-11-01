{
  den.aspects.laptop.nixos = {
    services.power-profiles-daemon.enable = true;
    services.scx.extraArgs = [ "--primary-domain=auto" ];

    services.upower.enable = true;
    services.fwupd.enable = true;

    hardware.alsa.enablePersistence = true;
  };
}
