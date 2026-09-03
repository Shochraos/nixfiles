{
  den.aspects.network =
    { host, ... }:
    {
      nixos = {
        networking.networkmanager.enable = true;
        networking.hostName = host.name;
      };
    };
}
