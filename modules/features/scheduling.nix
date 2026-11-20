{
  den.aspects.scheduling.nixos =
    { pkgs, ... }:
    {
      nix.settings.cores = 12;

      systemd.services.nix-daemon.serviceConfig = {
        AllowedCPUs = "0-11";
        MemoryHigh = "12G";
        MemoryMax = "16G";
      };

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
