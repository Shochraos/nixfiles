{
  den.aspects.wireguard =
    { host, ... }:
    {
      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          hostname = lib.toLower host.name;
          profiles = config.host.wireguard.profiles;
          profileNames = builtins.attrNames profiles;
          secretFor = name: "wireguard/${hostname}/${name}";
          ownsKey = name: !(profiles.${name} ? wireguard.private-key);
          envName = name: lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] name);
          keyVar = name: "WG_${envName name}_KEY";
          pskVar = name: "WG_${envName name}_PSK";
          hasPsk = name: profiles.${name}.presharedKey;
          extrasFor = name: profiles.${name}.extraSecrets;
          extraVar = name: extra: "WG_${envName name}_${envName extra}";
          secretEntries = builtins.concatMap (
            name:
            lib.optional (ownsKey name) {
              secret = secretFor name;
              var = keyVar name;
            }
            ++ lib.optional (hasPsk name) {
              secret = "${secretFor name}-psk";
              var = pskVar name;
            }
            ++ map (extra: {
              secret = "${secretFor name}-${extra}";
              var = extraVar name extra;
            }) (extrasFor name)
          ) profileNames;
          secrets = map (entry: entry.secret) secretEntries;
          variables = map (entry: entry.var) secretEntries;
          conditionalNames = builtins.filter (
            name: profiles.${name}.excludedSSIDs != [ ] && (profiles.${name}.connection.autoconnect or true)
          ) profileNames;
          keyReference = name: profiles.${name}.wireguard.private-key or ("$" + keyVar name);
          manualProfilesFor =
            name:
            builtins.filter (
              other:
              other != name
              && !(profiles.${other}.connection.autoconnect or true)
              && keyReference other == keyReference name
            ) profileNames;
          profileFile = name: "/run/NetworkManager/system-connections/${name}.nmconnection";
          reconcile = pkgs.writeShellScript "wireguard-autoconnect" ''
            set -euo pipefail
            export LC_ALL=C
            action=''${2:-}
            case "$action" in
            profiles-loaded | up | down | dhcp4-change | dhcp6-change | reapply) ;;
            *) exit 0 ;;
            esac
            export PATH=${
              lib.makeBinPath [
                config.networking.networkmanager.package
                pkgs.coreutils
                pkgs.util-linux
              ]
            }
            exec 9>/run/lock/wireguard-autoconnect.lock
            flock 9
            connections=$(nmcli --colors no --terse --escape no --fields UUID,TYPE,STATE,ACTIVE,FILENAME connection show) || exit 0
            devices=$(nmcli --colors no --terse --escape no --fields DEVICE,TYPE,STATE device status) || exit 0
            wifi=$(nmcli --colors no --terse --escape no --fields IN-USE,SSID device wifi list --rescan no) || exit 0
            declare -A uuids states counts
            event_type=
            event_file=
            while IFS=: read -r uuid type state active filename; do
              [[ $uuid != "''${CONNECTION_UUID:-}" ]] || event_type=$type
              filename=''${filename/#\/var\/run\//\/run\/}
              [[ $uuid != "''${CONNECTION_UUID:-}" ]] || event_file=$filename
              [[ -n $filename ]] || continue
              counts["$filename"]=$((''${counts["$filename"]:-0} + 1))
              if [[ $type == wireguard && $uuid =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ && ($active == yes || $active == no) ]]; then
                uuids["$filename"]=$uuid
                states["$filename"]=$state
              else
                uuids["$filename"]=
                states["$filename"]=
              fi
            done <<<"$connections"
            uplink=false
            physical_event=false
            event_device_present=false
            while IFS=: read -r device type state; do
              [[ $device != "''${1:-}" ]] || event_device_present=true
              case "$type" in
              ethernet | wifi | gsm | cdma | bluetooth)
                [[ $device != "''${1:-}" ]] || physical_event=true
                case "$state" in
                connected | "connected (externally)") uplink=true ;;
                esac
                ;;
              esac
            done <<<"$devices"
            case "$event_type" in
            802-3-ethernet | 802-11-wireless | gsm | cdma | bluetooth) physical_event=true ;;
            "")
              if [[ $action == down && -n ''${1:-} ]] && ! "$event_device_present"; then
                physical_event=true
              fi
              ;;
            esac
            reconcile_profile() {
              local name=$1 file=$2 manual_count=$3 uuid state excluded=false allow_start=true
              local in_use ssid denied pending manual_file manual_active=false manual_event=false
              shift 3
              local -a manual_files=("''${@:1:manual_count}")
              shift "$manual_count"
              local -a excluded_ssids=("$@")
              [[ ''${counts["$file"]:-0} == 1 && -n ''${uuids["$file"]:-} ]] || return 0
              uuid=''${uuids["$file"]}
              state=''${states["$file"]}
              pending=/run/wireguard-autoconnect-"$name".pending
              for manual_file in "''${manual_files[@]}"; do
                [[ $event_file != "$manual_file" ]] || manual_event=true
                [[ ''${counts["$manual_file"]:-0} != 0 ]] || continue
                if [[ ''${counts["$manual_file"]} != 1 || -z ''${uuids["$manual_file"]:-} || -n ''${states["$manual_file"]:-} ]]; then
                  manual_active=true
                fi
              done
              case "$action" in
              profiles-loaded) ;;
              up | down | dhcp4-change | dhcp6-change | reapply)
                if [[ ''${CONNECTION_UUID:-} == "$uuid" ]]; then
                  case "$action" in
                  down) [[ -e $pending ]] || return 0 ;;
                  up) allow_start=false ;;
                  *) return 0 ;;
                  esac
                elif ! "$physical_event" && ! "$manual_event"; then
                  return 0
                fi
                ;;
              *) return 0 ;;
              esac
              while IFS=: read -r in_use ssid; do
                [[ $in_use == '*' ]] || continue
                for denied in "''${excluded_ssids[@]}"; do
                  [[ $ssid != "$denied" ]] || excluded=true
                done
              done <<<"$wifi"
              if "$manual_active" || "$excluded" || ! "$uplink"; then
                rm -f -- "$pending"
                case "$state" in
                activating | activated) nmcli --wait 0 connection down uuid "$uuid" ;;
                esac
              elif "$allow_start"; then
                case "$state" in
                activating | activated) rm -f -- "$pending" ;;
                deactivating) touch -- "$pending" ;;
                "")
                  rm -f -- "$pending"
                  nmcli --wait 0 connection up uuid "$uuid"
                  ;;
                esac
              fi
            }
            ${lib.concatMapStringsSep "\n" (name: ''
              reconcile_profile ${
                lib.escapeShellArgs (
                  [
                    name
                    (profileFile name)
                    (toString (builtins.length (manualProfilesFor name)))
                  ]
                  ++ map profileFile (manualProfilesFor name)
                  ++ profiles.${name}.excludedSSIDs
                )
              }
            '') conditionalNames}
          '';
        in
        {
          config = lib.mkIf (profiles != { }) {
            assertions = [
              {
                assertion = builtins.length secrets == builtins.length (lib.unique secrets);
                message = "host.wireguard.profiles: generated secret identifiers collide.";
              }
              {
                assertion = builtins.length variables == builtins.length (lib.unique variables);
                message = "host.wireguard.profiles: profile names or extraSecrets collide after environment-variable normalization.";
              }
            ];

            sops.secrets = builtins.listToAttrs (map (entry: lib.nameValuePair entry.secret { }) secretEntries);

            sops.templates."wireguard.env".content = lib.concatLines (
              map (entry: "${entry.var}=${config.sops.placeholder.${entry.secret}}") secretEntries
            );

            systemd.services.NetworkManager-ensure-profiles.serviceConfig.ExecStartPost = lib.mkIf (
              conditionalNames != [ ]
            ) ''${reconcile} "" profiles-loaded'';

            networking.networkmanager.dispatcherScripts = lib.optional (conditionalNames != [ ]) {
              source = reconcile;
              type = "basic";
            };

            networking.networkmanager.ensureProfiles = {
              environmentFiles = [ config.sops.templates."wireguard.env".path ];

              profiles = builtins.mapAttrs (
                name: profile:
                let
                  withKey =
                    lib.recursiveUpdate
                      (removeAttrs profile [
                        "presharedKey"
                        "extraSecrets"
                        "excludedSSIDs"
                      ])
                      (
                        lib.optionalAttrs (ownsKey name) {
                          wireguard.private-key = "$" + keyVar name;
                        }
                        // lib.optionalAttrs (builtins.elem name conditionalNames) {
                          connection.autoconnect = false;
                        }
                      );
                  addPsk =
                    section: value:
                    if lib.hasPrefix "wireguard-peer." section then
                      value
                      // {
                        preshared-key = "$" + pskVar name;
                        preshared-key-flags = 0;
                      }
                    else
                      value;
                in
                if hasPsk name then builtins.mapAttrs addPsk withKey else withKey
              ) profiles;
            };
          };
        };
    };
}
