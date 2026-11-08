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
      firewall.allowedTCPPorts = [
        53
        853
      ];
      firewall.allowedUDPPorts = [
        53
        853
      ];
    };
    services.resolved.enable = false;

    sops.secrets = {
      "dns/adguard-password-hash" = { };
    };
    sops.templates."AdGuardHome.yaml" = {
      file = (pkgs.formats.yaml { }).generate "AdGuardHome.yaml" config.services.adguardhome.settings;
      mode = "0600";
      restartUnits = [ "adguardhome.service" ];
    };
    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      openFirewall = true;
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
            "https://1.1.1.1/dns-query"
            "https://1.0.0.1/dns-query"
          ];
          bootstrap_dns = [
            "1.1.1.1"
            "1.0.0.1"
          ];
          fallback_dns = [ ];
          upstream_mode = "load_balance";
          aaaa_disabled = false;
          allowed_clients = [
            "127.0.0.0/8"
            "::1/128"
            "192.168.1.0/24"
            "192.168.10.0/24"
            "192.168.20.0/24"
            "192.168.30.0/24"
            "192.168.40.0/24"
            "192.168.50.0/24"
            "192.168.60.0/24"
            "fdba:457d:2cbe:1::/64"
            "fdba:457d:2cbe:10::/64"
            "fdba:457d:2cbe:20::/64"
            "fdba:457d:2cbe:30::/64"
            "fdba:457d:2cbe:40::/64"
            "fdba:457d:2cbe:50::/64"
            "fdba:457d:2cbe:60::/64"
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
            name = "HaGeZi Multi PRO++";
            url = "https://hagezi-mirror.dnsbunker.org/adblock/pro.plus.txt";
          }
          {
            enabled = true;
            id = 2;
            name = "HaGeZi Threat Intelligence Feeds";
            url = "https://hagezi-mirror.dnsbunker.org/adblock/tif.txt";
          }
          {
            enabled = true;
            id = 3;
            name = "HaGeZi DynDNS";
            url = "https://hagezi-mirror.dnsbunker.org/adblock/dyndns.txt";
          }
          {
            enabled = true;
            id = 4;
            name = "HaGeZi Encrypted DNS Bypass";
            url = "https://hagezi-mirror.dnsbunker.org/adblock/doh.txt";
          }
          {
            enabled = true;
            id = 5;
            name = "HaGeZi Native Amazon";
            url = "https://hagezi-mirror.dnsbunker.org/adblock/native.amazon.txt";
          }
          {
            enabled = true;
            id = 6;
            name = "HaGeZi Native Microsoft";
            url = "https://hagezi-mirror.dnsbunker.org/adblock/native.winoffice.txt";
          }
          {
            enabled = true;
            id = 7;
            name = "HaGeZi Native Samsung";
            url = "https://hagezi-mirror.dnsbunker.org/adblock/native.samsung.txt";
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
          enabled = true;
          port_https = 0;
          port_dns_over_tls = 853;
          port_dns_over_quic = 853;
          port_dnscrypt = 0;
          certificate_path = "/run/credentials/adguardhome.service/acme-fullchain";
          private_key_path = "/run/credentials/adguardhome.service/acme-key";
        };
      };
    };
    systemd.services.adguardhome = {
      requires = [ "acme-home.service" ];
      after = [ "acme-home.service" ];
      preStart = lib.mkForce "";
      serviceConfig = {
        LoadCredential = [
          "adguard-config:${config.sops.templates."AdGuardHome.yaml".path}"
          "acme-fullchain:${config.security.acme.certs.home.directory}/fullchain.pem"
          "acme-key:${config.security.acme.certs.home.directory}/key.pem"
        ];
        ExecStartPre = "${pkgs.coreutils}/bin/install -m0600 %d/adguard-config /var/lib/AdGuardHome/AdGuardHome.yaml";
      };
    };
  };
}
