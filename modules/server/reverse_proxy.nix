{ lib, den, ... }:
{
  den.aspects.reverse_proxy.includes = [ den.aspects.certificates ];
  den.aspects.reverse_proxy.nixos =
    { config, ... }:
    let
      sites = {
        # DNS
        dns1 = "127.0.0.1:3000";
        dns2 = "192.168.10.254:3000";

        # Hosts
        unraid = "192.168.10.2:80";
        unifi = "192.168.1.1:80";
        fritz = "192.168.178.1:80";

        # Containers
        attic = "192.168.10.2:8085";
        autobrr = "192.168.10.2:7474";
        cloud = "192.168.10.2:8666";
        hermes = "192.168.10.2:9119";
        immich = "192.168.10.2:2283";
        jellyfin = "192.168.10.2:8096";
        komga = "192.168.10.2:25600";
        prowlarr = "192.168.10.2:9696";
        qui = "192.168.10.2:7476";
        stash = "192.168.10.2:9999";
        usenet = "192.168.10.2:8080";
      };
      pathSites = {
        radarr = {
          anime = "192.168.10.2:7878";
          german = "192.168.10.2:7879";
          movies = "192.168.10.2:7880";
        };
        sonarr = {
          anime = "192.168.10.2:8989";
          german = "192.168.10.2:8990";
          tv = "192.168.10.2:8991";
        };
      };
      unrestrictedSites = [ "jellyfin" ];
      allowedClientRanges = [
        "192.168.2.0/24"
        "192.168.10.0/24"
        "192.168.20.0/24"
        "fdba:457d:2cbe:2::/64"
        "fdba:457d:2cbe:10::/64"
        "fdba:457d:2cbe:20::/64"
      ];
      accessGuard =
        site:
        lib.optionalString (!(builtins.elem site unrestrictedSites)) ''
          @denied not remote_ip ${lib.concatStringsSep " " allowedClientRanges}
          respond @denied "Forbidden" 403
        '';
      virtualHost = site: extraConfig: {
        hostName = "https://${site}.{$CADDY_HOME_DOMAIN}";
        useACMEHost = "home";
        logFormat = "output discard";
        inherit extraConfig;
      };
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
        virtualHosts =
          lib.mapAttrs (
            site: destination:
            virtualHost site (
              accessGuard site
              + ''
                reverse_proxy ${destination}
              ''
            )
          ) sites
          // lib.mapAttrs (
            site: paths:
            virtualHost site ''
              route {
                ${accessGuard site}
                redir / /anime/ 302
                ${lib.concatStrings (
                  lib.mapAttrsToList (path: destination: ''
                    @${path} path /${path} /${path}/*
                    reverse_proxy @${path} ${destination}
                  '') paths
                )}
                respond 404
              }
            ''
          ) pathSites;
      };
    };
}
