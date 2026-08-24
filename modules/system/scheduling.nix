{
  den.aspects.scheduling.nixos =
    { pkgs, ... }:
    {
      services.scx = {
        enable = true;
        scheduler = "scx_bpfland";
      };

      services.ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos;
        settings = {
          cgroups = false;
        };
      };
    };
}
