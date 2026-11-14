{ lib, den, ... }:
{
  den.aspects.reverse_proxy.includes = [ den.aspects.certificates ];
  den.aspects.reverse_proxy.nixos =
    { config, ... }:
    let
      sites = {
        dns1 = "127.0.0.1:3000";
        dns2 = "192.168.10.254:3000";
        attic = "192.168.10.2:8085";
      };
      unrestrictedSites = [ "proxy2" ];
      allowedClientRanges = [
        "192.168.2.0/24"
        "192.168.10.0/24"
        "192.168.20.0/24"
        "fdba:457d:2cbe:2::/64"
        "fdba:457d:2cbe:10::/64"
        "fdba:457d:2cbe:20::/64"
      ];
    in
    {
      sops.templates."caddy.env" = {
        content = ''
          CADDY_HOME_DOMAIN=${config.sops.placeholder."network/home-domain"}
        '';
        mode = "0400";
        restartUnits = [ "caddy.service" ];
      };
      services.caddy = {
        enable = true;
        openFirewall = true;
        environmentFile = config.sops.templates."caddy.env".path;
        globalConfig = ''
          auto_https disable_certs
        '';
        virtualHosts = lib.mapAttrs (site: destination: {
          hostName = "https://${site}.{$CADDY_HOME_DOMAIN}";
          useACMEHost = "home";
          logFormat = "output discard";
          extraConfig =
            lib.optionalString (!(builtins.elem site unrestrictedSites)) ''
              @denied not remote_ip ${lib.concatStringsSep " " allowedClientRanges}
              respond @denied "Forbidden" 403
            ''
            + ''
              reverse_proxy ${destination}
            '';
        }) sites;
      };
    };
}
