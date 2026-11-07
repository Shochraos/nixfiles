{ lib, ... }:
{
  den.aspects.dns-server.nixos = { config, pkgs, ... }: {
    networking = {
      networkmanager.dns = "none";
      nameservers = [
        "127.0.0.1"
        "::1"
      ];
      resolvconf.useLocalResolver = true;
      firewall.allowedTCPPorts = [ 53 ];
      firewall.allowedUDPPorts = [ 53 ];
    };
    services.resolved.enable = false;
    services.timesyncd = {
      enable = true;
      servers = [
        "162.159.200.1"
        "162.159.200.123"
        "2606:4700:f1::1"
        "2606:4700:f1::123"
      ];
      fallbackServers = [ ];
    };

    sops.secrets."dns/adguard-password-hash" = { };
    sops.templates."AdGuardHome.yaml" = {
      file = (pkgs.formats.yaml { }).generate "AdGuardHome.yaml" config.services.adguardhome.settings;
      mode = "0600";
      restartUnits = [ "adguardhome.service" ];
    };
    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      openFirewall = false;
      allowDHCP = false;
      settings = {
        http = {
          address = "127.0.0.1:3000";
          pprof.enabled = false;
        };
        users = [
          {
            name = "shochraos";
            password = config.sops.placeholder."dns/adguard-password-hash";
          }
        ];
        auth_attempts = 5;
        block_auth_min = 15;
        dns = {
          bind_hosts = [
            "0.0.0.0"
            "::"
          ];
          port = 53;
          serve_plain_dns = true;
          upstream_dns = [
            "sdns://AgcAAAAAAAAABzEuMC4wLjEAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5"
            "sdns://AgcAAAAAAAAAFlsyNjA2OjQ3MDA6NDcwMDo6MTExMV0AGlsyNjA2OjQ3MDA6NDcwMDo6MTExMV06NDQzCi9kbnMtcXVlcnk"
            "sdns://AgcAAAAAAAAAFlsyNjA2OjQ3MDA6NDcwMDo6MTAwMV0AGlsyNjA2OjQ3MDA6NDcwMDo6MTAwMV06NDQzCi9kbnMtcXVlcnk"
          ];
          bootstrap_dns = [ ];
          fallback_dns = [ ];
          upstream_mode = "load_balance";
          aaaa_disabled = false;
          allowed_clients = [
            "127.0.0.0/8"
            "::1/128"
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
            "fc00::/7"
            "fe80::/10"
          ];
          ratelimit = 100;
          ratelimit_subnet_len_ipv4 = 32;
          ratelimit_subnet_len_ipv6 = 128;
          ratelimit_whitelist = [
            "127.0.0.1"
            "::1"
          ];
          refuse_any = true;
          edns_client_subnet.enabled = false;
          use_private_ptr_resolvers = false;
          local_ptr_upstreams = [ ];
        };
        clients.runtime_sources.rdns = false;
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
          filters_update_interval = 24;
          parental_enabled = false;
          safebrowsing_enabled = false;
          safe_search.enabled = false;
        };
        filters = [
          {
            enabled = true;
            id = 1;
            name = "AdGuard DNS filter";
            url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
          }
        ];
        querylog = {
          enabled = true;
          file_enabled = true;
          interval = "24h";
        };
        statistics = {
          enabled = true;
          interval = "168h";
        };
        dhcp.enabled = false;
        tls = {
          enabled = false;
          port_https = 0;
          port_dns_over_tls = 0;
          port_dns_over_quic = 0;
          port_dnscrypt = 0;
        };
      };
    };
    systemd.services.adguardhome = {
      preStart = lib.mkForce "";
      serviceConfig = {
        LoadCredential = [ "adguard-config:${config.sops.templates."AdGuardHome.yaml".path}" ];
        ExecStartPre = "${pkgs.coreutils}/bin/install -m0600 %d/adguard-config /var/lib/AdGuardHome/AdGuardHome.yaml";
      };
    };
  };
}
