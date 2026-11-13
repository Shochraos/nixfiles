{ lib, den, ... }:
{
  den.aspects.reverse_proxy.includes = [ den.aspects.certificates ];
  den.aspects.reverse_proxy.nixos =
    { config, ... }:
    let
      sites = [
        "proxy"
        "proxy2"
      ];
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
      assertions = [
        {
          assertion = lib.all (site: builtins.match "[a-z][a-z0-9_]*" site != null) sites;
          message = "Caddy site identifiers must start with a lowercase letter and contain only lowercase letters, digits, and underscores.";
        }
        {
          assertion = builtins.length sites == builtins.length (lib.unique sites);
          message = "Caddy site identifiers must be unique.";
        }
        {
          assertion = lib.all (site: builtins.elem site sites) unrestrictedSites;
          message = "Unrestricted Caddy sites must be present in the site list.";
        }
      ];
      sops.secrets = lib.genAttrs (lib.concatMap (site: [
        "caddy/${site}/domain"
        "caddy/${site}/destination"
      ]) sites) (_: { });
      sops.templates."caddy.env" = {
        content = lib.concatMapStrings (site: ''
          CADDY_${lib.toUpper site}_DOMAIN=${config.sops.placeholder."caddy/${site}/domain"}
          CADDY_${lib.toUpper site}_DESTINATION=${config.sops.placeholder."caddy/${site}/destination"}
        '') sites;
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
        virtualHosts = lib.genAttrs sites (site: {
          hostName = "https://{$CADDY_${lib.toUpper site}_DOMAIN}";
          useACMEHost = "home";
          logFormat = "output discard";
          extraConfig =
            lib.optionalString (!(builtins.elem site unrestrictedSites)) ''
              @denied not remote_ip ${lib.concatStringsSep " " allowedClientRanges}
              respond @denied "Forbidden" 403
            ''
            + ''
              reverse_proxy {$CADDY_${lib.toUpper site}_DESTINATION}
            '';
        });
      };
    };
}
