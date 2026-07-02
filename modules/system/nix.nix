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

    nixpkgs.config = {
      allowUnfree = true;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
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

      home.packages = with pkgs; [ nix-init ];
    };
}
