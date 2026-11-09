{
  den.aspects.scheduling.nixos =
    { pkgs, ... }:
    {
      services.scx-loader = {
        enable = true;
        config.default_sched = "scx_bpfland";
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
