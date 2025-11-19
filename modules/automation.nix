{ ... }:
{
  # Enable automatic Optimization of nix store size
  nix.optimise =
  {
    automatic = true;
    dates = [ "daily" ];
  };

  # Enable automaticUpgrade
  system.autoUpgrade =
  {
    enable = true;
    dates = "weekly";
  };
}
