{
  den.aspects.wireguard =
    { host, ... }:
    {
      nixos =
        { config, lib, ... }:
        let
          hostname = lib.toLower host.name;
          profiles = config.host.wireguard.profiles;
          profileNames = builtins.attrNames profiles;
          secretFor = name: "wireguard/${hostname}/${name}";
          ownsKey = name: !(profiles.${name} ? wireguard.private-key);
          envName = name: lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] name);
          keyVar = name: "WG_${envName name}_KEY";
          pskVar = name: "WG_${envName name}_PSK";
          hasPsk = name: profiles.${name}.presharedKey or false;
          extrasFor = name: profiles.${name}.extraSecrets or [ ];
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
                      ])
                      (
                        lib.optionalAttrs (ownsKey name) {
                          wireguard.private-key = "$" + keyVar name;
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
