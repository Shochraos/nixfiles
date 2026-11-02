{
  config,
  ...
}:
let
  inherit (config) assets;
in
{
  den.aspects.network =
    { host, user, ... }:
    {
      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          ssh = config.host.ssh;
          sshEnabled = ssh.authorizedKeys != [ ];
          homeV4 = config.sops.secrets."network/home-ipv4".path;
          homeV6 = config.sops.secrets."network/home-ipv6".path;
          sopsUnit = lib.optional config.sops.useSystemdActivation "sops-install-secrets.service";
          maxMultiportSlots = 15;
          normalizePorts = protocol: {
            ports = lib.unique (lib.sort (a: b: a < b) protocol.ports);
            ranges = lib.unique (
              lib.sort (a: b: a.from < b.from || (a.from == b.from && a.to < b.to)) protocol.ranges
            );
          };
          multiportSlots = protocol: builtins.length protocol.ports + 2 * builtins.length protocol.ranges;
          formatPorts =
            protocol:
            let
              renderRange = range: "${toString range.from}:${toString range.to}";
            in
            lib.concatStringsSep "," (map renderRange protocol.ranges ++ map toString protocol.ports);
          tcp = normalizePorts config.host.network.homeOnlyPorts.tcp;
          udp = normalizePorts config.host.network.homeOnlyPorts.udp;
          tcpPorts = formatPorts tcp;
          udpPorts = formatPorts udp;
          homeNetwork = pkgs.writeShellApplication {
            name = "home-network";
            runtimeInputs = [
              config.networking.firewall.package
              config.systemd.package
              pkgs.coreutils
              pkgs.iprange
              pkgs.iproute2
              pkgs.jq
              pkgs.networkmanager
              pkgs.util-linux
            ];
            runtimeEnv = {
              HOME_NETWORK_TCP_PORTS = tcpPorts;
              HOME_NETWORK_UDP_PORTS = udpPorts;
            };
            text = builtins.readFile assets.homeNetworkScript;
          };
          applyCommand = "${homeNetwork}/bin/home-network apply ${homeV4} ${homeV6}";
        in
        {
          assertions = [
            {
              assertion = config.networking.firewall.backend == "iptables";
              message = "The home-LAN service policy requires the iptables firewall backend.";
            }
            {
              assertion = multiportSlots tcp <= maxMultiportSlots;
              message = "host.network.homeOnlyPorts.tcp: multiport matches support at most ${toString maxMultiportSlots} slots, and a range occupies two.";
            }
            {
              assertion = multiportSlots udp <= maxMultiportSlots;
              message = "host.network.homeOnlyPorts.udp: multiport matches support at most ${toString maxMultiportSlots} slots, and a range occupies two.";
            }
          ];

          networking.networkmanager.enable = true;
          systemd.services.NetworkManager-wait-online.enable = config.host.network.onlinePolicy == "wait";

          networking.hostName = host.name;
          networking.firewall.enable = true;

          sops.secrets."network/home-ipv4" = {
            restartUnits = [ "home-network.service" ];
          };
          sops.secrets."network/home-ipv6" = {
            restartUnits = [ "home-network.service" ];
          };

          systemd.services.home-network = {
            description = "Home LAN scoped service trust";
            wantedBy = [ "multi-user.target" ];
            wants = [
              "NetworkManager.service"
              "firewall.service"
            ]
            ++ sopsUnit;
            after = [
              "NetworkManager.service"
              "firewall.service"
            ]
            ++ sopsUnit;
            partOf = [ "firewall.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = applyCommand;
              ExecReload = applyCommand;
              ExecStop = "${homeNetwork}/bin/home-network clear";
            };
          };

          systemd.services.home-network-cleanup = {
            description = "Home LAN scoped service trust cleanup";
            wantedBy = [ "multi-user.target" ];
            before = [ "home-network.service" ];
            partOf = [ "firewall.service" ];
            stopIfChanged = false;
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.coreutils}/bin/true";
              ExecStop = "${homeNetwork}/bin/home-network cleanup";
            };
          };

          systemd.services.firewall = {
            wants = [
              "home-network.service"
              "home-network-cleanup.service"
            ];
            unitConfig.PropagatesReloadTo = [ "home-network.service" ];
          };

          networking.networkmanager.dispatcherScripts = [
            {
              source = pkgs.writeShellScript "90-home-network" ''
                exec ${homeNetwork}/bin/home-network apply ${homeV4} ${homeV6}
              '';
              type = "basic";
            }
          ];

          networking.firewall.extraCommands = ''
            ${homeNetwork}/bin/home-network setup-static || true
          '';

          services.openssh = {
            enable = sshEnabled;
            openFirewall = false;
            authorizedKeysInHomedir = false;

            settings = {
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
              PermitRootLogin = "no";
              AllowUsers = [ user.name ];
              MaxAuthTries = 3;
              LoginGraceTime = 20;
            };
          };

          users.users.${user.name}.openssh.authorizedKeys.keys = ssh.authorizedKeys;

          networking.firewall.interfaces = lib.mkIf sshEnabled (
            lib.genAttrs
              (map (
                pattern:
                if config.networking.firewall.backend == "iptables" then
                  lib.replaceStrings [ "*" ] [ "+" ] pattern
                else
                  pattern
              ) ssh.firewallInterfaces)
              (_: {
                allowedTCPPorts = [ 22 ];
              })
          );
        };
    };
}
