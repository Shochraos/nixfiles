{
  aspects.network =
    { systemname, ... }:
    {
      networking.networkmanager.enable = true;
      networking.hostName = systemname;
    };
}
