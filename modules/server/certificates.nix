{ lib, ... }:
{
  den.aspects.certificates.nixos =
    { config, pkgs, ... }:
    let
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
      sops.secrets = {
        "dns/cloudflare-dns-api-token" = { };
        "network/home-domain".restartUnits = [
          "acme-home.service"
          "acme-order-renew-home.service"
        ];
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
                if [ -e out/acme-success ] && ${lib.getExe pkgs.openssl} x509 -in out/cert.pem -noout -checkhost "dns1.$runtimeDomain" >/dev/null 2>&1 && ${lib.getExe pkgs.openssl} x509 -in out/cert.pem -noout -checkhost "dns2.$runtimeDomain" >/dev/null 2>&1; then
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
    };
}
