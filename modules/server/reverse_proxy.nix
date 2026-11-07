{ lib, ... }:
{
  den.aspects.reverse_proxy.nixos =
    { config, pkgs, ... }:
    let
      sites = [
        "proxy"
        "proxy2"
      ];
      runtimeDomain = ''
        set +x
        set -euo pipefail
        export LC_ALL=C
        runtimeDomain=
        if IFS= read -r -d "" runtimeDomain < "$CREDENTIALS_DIRECTORY/home-domain"; then
          echo "Invalid ACME domain credential" >&2
          exit 1
        fi
        runtimeDomain=''${runtimeDomain%$'\n'}
        label='[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
        if (( ''${#runtimeDomain} > 251 )) || ! [[ $runtimeDomain =~ ^$label(\.$label)+$ ]]; then
          echo "Invalid ACME domain credential" >&2
          exit 1
        fi
      '';
      replaceNative =
        replacements: script:
        let
          result = builtins.replaceStrings (map (r: r.from) replacements) (map (r: r.to) replacements) script;
        in
        assert lib.assertMsg (
          lib.all (r: builtins.length (lib.splitString r.from script) == r.count + 1) replacements
          && lib.all (r: !(lib.hasInfix r.from result)) replacements
          && !(lib.hasInfix "set -x" result)
          && !(lib.hasInfix "set -ex" result)
        ) "Native ACME runtime-domain adapter no longer matches the pinned scripts";
        runtimeDomain + result;
      domainCredential = "home-domain:${config.sops.secrets."network/home-domain".path}";
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
      ];
      sops.secrets = {
        "dns/cloudflare-dns-api-token" = { };
        "network/home-domain".restartUnits = [
          "acme-home.service"
          "acme-order-renew-home.service"
        ];
      }
      // lib.genAttrs (lib.concatMap (site: [
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
      security.acme = {
        acceptTerms = true;
        defaults = {
          server = "https://acme-v02.api.letsencrypt.org/directory";
        };
        certs.home = {
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
          dnsPropagationCheck = true;
          enableDebugLogs = false;
          credentialFiles = {
            CF_DNS_API_TOKEN_FILE = config.sops.secrets."dns/cloudflare-dns-api-token".path;
          };
          reloadServices = [ "adguardhome.service" ];
        };
      };
      systemd.services.acme-home = _: {
        options.script = lib.mkOption {
          apply = replaceNative [
            {
              from = "set -ex";
              to = "set -e";
              count = 1;
            }
            {
              from = "'--domains=home'";
              to = ''"--domains=*.$runtimeDomain"'';
              count = 1;
            }
            {
              from = "cd 'home'";
              to = ''cd "_.$runtimeDomain"'';
              count = 1;
            }
            {
              from = "cp -vp cert.pem ../out/cert.pem";
              to = "cp --remove-destination -vp cert.pem ../out/cert.pem";
              count = 1;
            }
            {
              from = ''
                if [ -e out/acme-success ]; then
                  exit 0
                fi'';
              to = ''
                if [ -e out/acme-success ] && ${lib.getExe pkgs.openssl} x509 -in out/cert.pem -noout -checkhost "dns1.$runtimeDomain" >/dev/null 2>&1; then
                  exit 0
                fi
                rm -f out/acme-success'';
              count = 1;
            }
          ];
        };
        config.serviceConfig.LoadCredential = [ domainCredential ];
      };
      systemd.services.acme-order-renew-home = _: {
        options.script = lib.mkOption {
          apply = replaceNative [
            {
              from = "-d home";
              to = ''-d "*.$runtimeDomain"'';
              count = 2;
            }
            {
              from = "'certificates/home.key'";
              to = ''"certificates/_.$runtimeDomain.key"'';
              count = 2;
            }
            {
              from = "'certificates/home.crt'";
              to = ''"certificates/_.$runtimeDomain.crt"'';
              count = 3;
            }
            {
              from = "'certificates/home.issuer.crt'";
              to = ''"certificates/_.$runtimeDomain.issuer.crt"'';
              count = 1;
            }
          ];
        };
        config.serviceConfig.LoadCredential = [ domainCredential ];
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
          extraConfig = ''
            reverse_proxy {$CADDY_${lib.toUpper site}_DESTINATION}
          '';
        });
      };
    };
}
