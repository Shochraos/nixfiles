{
  den.aspects.laptop.nixos = {
    services.power-profiles-daemon.enable = true;
    services.scx-loader.config.scheds.scx_bpfland.auto_mode = [ "--primary-domain=auto" ];

    services.upower.enable = true;
    services.fwupd.enable = true;

    hardware.alsa.enablePersistence = true;
  };
}
