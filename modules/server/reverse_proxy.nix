{ lib, ... }:
{
  den.aspects.reverse_proxy.nixos =
    { config, ... }:
    let
      namespace = "home.example.invalid";
      hostname = "${lib.toLower config.networking.hostName}.${namespace}";
    in
    {
      sops.secrets."dns/cloudflare-dns-api-token" = { };
      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "admin@example.invalid";
          server = "https://acme-staging-v02.api.letsencrypt.org/directory";
        };
        certs.${namespace} = {
          domain = "*.${namespace}";
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
          dnsPropagationCheck = true;
          credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets."dns/cloudflare-dns-api-token".path;
        };
      };
      services.caddy = {
        enable = true;
        openFirewall = true;
        globalConfig = ''
          auto_https off
          servers {
            protocols h1 h2
          }
        '';
        virtualHosts."https://${hostname}" = {
          useACMEHost = namespace;
          logFormat = "output discard";
          extraConfig = ''
            reverse_proxy 127.0.0.1:3000
          '';
        };
      };
    };
}
