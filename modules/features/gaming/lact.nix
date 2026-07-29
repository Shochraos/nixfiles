{
  den.aspects.gaming.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ lact ];
      systemd = {
        packages = with pkgs; [ lact ];
        services.lactd.wantedBy = [ "multi-user.target" ];
      };
    };
}
