{
  den.aspects.nix = _: {
    nixos = {
      nix = {
        settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        settings.substituters = [
          "https://cache.nixos-cuda.org"
          "https://nix-community.cachix.org"
        ];
        settings.trusted-public-keys = [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
