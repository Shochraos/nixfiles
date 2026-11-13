{
  den.aspects.utilities.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        net-tools
        dnsutils
      ];
    };
}
