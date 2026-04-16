{ pkgs, ... }:
{
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ "--performance" ];
  };

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    settings = {
      cgroups = false;
    };
  };
}
