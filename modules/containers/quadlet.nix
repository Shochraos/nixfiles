{ inputs, ... }:
let
  containerUser = "containerUser";
  containerHome = "/var/lib/containers";
in
{
  aspects.nixos.quadlet = {
    boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;
    virtualisation.quadlet.enable = true;

    users.groups.${containerUser}.gid = 700;

    users.users.${containerUser} = {
      isSystemUser = true;
      group = containerUser;
      uid = 700;
      home = containerHome;
      createHome = true;
      linger = true;
      autoSubUidGidRange = true;
      shell = "/run/current-system/sw/bin/bash";
    };

    home-manager.users.${containerUser} = {
      imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];

      home.username = containerUser;
      home.homeDirectory = containerHome;
      home.stateVersion = "25.05";

      virtualisation.quadlet.networks.internal.networkConfig.subnets = [ "172.16.0.0/24" ];
    };
  };
}
