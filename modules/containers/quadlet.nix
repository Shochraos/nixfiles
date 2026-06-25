{ ... }:
{
  aspects.nixos.quadlet = {
    virtualisation.quadlet.enable = true;

    virtualisation.quadlet.networks.internal.networkConfig.subnets = [ "172.16.0.0/24" ];
  };
}
