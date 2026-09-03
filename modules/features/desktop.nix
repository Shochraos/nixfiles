{
  den.aspects.desktop.nixos = {
    services.scx.extraArgs = [ "--primary-domain=performance" ];

    systemd.targets = {
      "suspend".enable = false;
      "hibernate".enable = false;
      "hybrid-sleep".enable = false;
      "suspend-then-hibernate".enable = false;
    };
  };
}
