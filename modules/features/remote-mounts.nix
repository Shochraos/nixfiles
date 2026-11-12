{
  den.aspects.remote-mounts =
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
          shares = [
            "appdata"
            "backups"
            "data"
            "misc"
            "projects"
          ];
          needsNetworkReadiness = host.name == "Solas";
          networkReady = pkgs.writeShellScript "astaroth-network-ready" ''
            set -euo pipefail
            export LC_ALL=C
            export PATH=${
              lib.makeBinPath [
                config.networking.networkmanager.package
                pkgs.systemd
              ]
            }
            home_ssid=${lib.escapeShellArg config.host.wifi.profiles.ragnarok.wifi.ssid}
            declare -A profile_interfaces=(
              ${lib.concatMapStringsSep "\n"
                (name: ''
                  [${lib.escapeShellArg "/run/NetworkManager/system-connections/${name}.nmconnection"}]=${
                    lib.escapeShellArg config.host.wireguard.profiles.${name}.connection.interface-name
                  }
                '')
                [
                  "home"
                  "home-split"
                ]
              }
            )
            ready() {
              local connections devices wifi uuid type state active filename device in_use ssid
              connections=$(nmcli --colors no --terse --escape no --fields UUID,TYPE,STATE,ACTIVE,FILENAME connection show) || return 1
              devices=$(nmcli --colors no --terse --escape no --fields DEVICE,TYPE,STATE device status) || return 1
              while IFS=: read -r uuid type state active filename; do
                filename=''${filename/#\/var\/run\//\/run\/}
                [[ $type == wireguard && $state == activated && $active == yes ]] || continue
                [[ $uuid =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || continue
                [[ -n $filename && -n ''${profile_interfaces["$filename"]:-} ]] || continue
                while IFS=: read -r device type state; do
                  if [[ $device == "''${profile_interfaces["$filename"]}" && $type == wireguard && $state == connected ]]; then
                    return 0
                  fi
                done <<<"$devices"
              done <<<"$connections"
              while IFS=: read -r device type state; do
                [[ $type == wifi && $state == connected ]] || continue
                wifi=$(nmcli --colors no --terse --escape no --fields IN-USE,SSID device wifi list ifname "$device" --rescan no) || return 1
                while IFS=: read -r in_use ssid; do
                  [[ $in_use != '*' || $ssid != "$home_ssid" ]] || return 0
                done <<<"$wifi"
              done <<<"$devices"
              return 1
            }
            deadline=$((SECONDS + 60))
            coproc network_events {
              export SYSTEMD_LOG_TARGET=console SYSTEMD_LOG_LEVEL=info SYSTEMD_COLORS=0 SYSTEMD_URLIFY=0
              exec busctl --system --match="type='signal',sender='org.freedesktop.NetworkManager'" monitor 2>&1
            }
            monitor_pid=$!
            exec {monitor_fd}<&"''${network_events[0]}"
            trap '
              kill "$monitor_pid" 2>/dev/null || :
              wait "$monitor_pid" 2>/dev/null || :
              exec {monitor_fd}<&-
            ' EXIT
            trap 'exit 1' HUP INT TERM
            subscribed=false
            while ((SECONDS < deadline)); do
              IFS= read -r -t "$((deadline - SECONDS))" -u "$monitor_fd" event || exit 1
              if ! "$subscribed"; then
                [[ $event == 'Monitoring bus message stream.' ]] || continue
                subscribed=true
              else
                [[ $event == *'Type=signal'* ]] || continue
              fi
              kill -0 "$monitor_pid" 2>/dev/null || exit 1
              if ready; then
                kill -0 "$monitor_pid" 2>/dev/null || exit 1
                exit 0
              fi
            done
            exit 1
          '';
        in
        {
          assertions = [
            {
              assertion = !config.sops.useSystemdActivation;
              message = "Astaroth SMB mount drop-ins require SOPS installation during activation, before systemd loads mount units.";
            }
          ];

          sops.secrets = {
            "astaroth/smb-username" = { };
            "astaroth/smb-password" = { };
            "network/home-domain" = { };
          };

          sops.templates = {
            "astaroth-smb-credentials" = {
              owner = "root";
              group = "root";
              mode = "0400";
              content = ''
                username=${config.sops.placeholder."astaroth/smb-username"}
                password=${config.sops.placeholder."astaroth/smb-password"}
              '';
            };
          }
          // builtins.listToAttrs (
            map (
              share:
              lib.nameValuePair "astaroth-smb-${share}" {
                path = "/run/systemd/system/mnt-astaroth-${share}.mount.d/50-hostname.conf";
                owner = "root";
                group = "root";
                mode = "0400";
                content = ''
                  [Mount]
                  What=//astaroth.${config.sops.placeholder."network/home-domain"}/${share}
                '';
              }
            ) shares
          );

          systemd.tmpfiles.rules = [
            "d /mnt/astaroth 0700 ${user.name} ${config.users.users.${user.name}.group} -"
          ];

          systemd.services.astaroth-network-ready = lib.mkIf needsNetworkReadiness {
            description = "Wait for the home network before mounting Astaroth shares";
            requires = [ "NetworkManager.service" ];
            after = [ "NetworkManager.service" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = networkReady;
              TimeoutStartSec = "60s";
              RemainAfterExit = false;
            };
          };

          boot.supportedFilesystems.cifs = true;

          systemd.units = builtins.listToAttrs (
            map (
              share:
              lib.nameValuePair "mnt-astaroth-${share}.mount" {
                text = lib.generators.toINI { } {
                  Unit = {
                    Description = "Astaroth ${share} share";
                  }
                  // lib.optionalAttrs needsNetworkReadiness {
                    Requires = "astaroth-network-ready.service";
                    After = "astaroth-network-ready.service";
                  };
                  Mount = {
                    Where = "/mnt/astaroth/${share}";
                    Type = "cifs";
                    TimeoutSec = "30s";
                    Options = lib.concatStringsSep "," (
                      [
                        "_netdev"
                        "nodev"
                        "nofail"
                        "nosuid"
                        "credentials=${config.sops.templates."astaroth-smb-credentials".path}"
                        "uid=${user.name}"
                        "gid=${config.users.users.${user.name}.group}"
                        "vers=3.1.1"
                        "seal"
                        "cache=strict"
                      ]
                      ++ (
                        if share == "projects" then
                          [
                            "posix"
                            "exec"
                          ]
                        else
                          [
                            "noexec"
                            "file_mode=0600"
                            "dir_mode=0700"
                          ]
                      )
                    );
                  };
                };
              }
            ) shares
          );

          systemd.automounts = map (share: {
            where = "/mnt/astaroth/${share}";
            wantedBy = [ "remote-fs.target" ];
            automountConfig.TimeoutIdleSec = "5min";
          }) shares;
        };
    };
}
