{
  aspects.nixos.nix = {
    nix = {
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      settings.download-buffer-size = 524288000;

      optimise = {
        automatic = true;
        dates = [ "daily" ];
      };
    };

    systemd.timers."nix-gc.timer".timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };

    nixpkgs.config = {
      allowUnfree = true;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };

    system.stateVersion = "25.05";
  };

  aspects.home.nix =
    { inputs, pkgs, ... }:
    {
      imports = [ inputs.nix-index-database.homeModules.default ];

      programs.nix-index = {
        enable = true;
        enableFishIntegration = true;
      };
      programs.nix-index-database.comma.enable = true;

      home.stateVersion = "25.05";
      home.packages = with pkgs; [ nix-init ];
    };
}
