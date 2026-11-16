{
  den.aspects.nix = _: {
    nixos = {
      nix = {
        settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        settings.download-buffer-size = 524288000;
        settings.sync-before-registering = true;
        settings.auto-optimise-store = true;

        channel.enable = false;
      };

      programs.nh.clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 10";
      };
    };

  };
}
