{
  den.aspects.desktop.nixos = {
    services.scx.extraArgs = [ "--performance" ];

    systemd.targets = {
      "suspend".enable = false;
      "hibernate".enable = false;
      "hybrid-sleep".enable = false;
      "suspend-then-hibernate".enable = false;
    };
  };
}
