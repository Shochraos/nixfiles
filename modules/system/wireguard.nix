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
          envName = name: lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] name);
          keyVar = name: "WG_${envName name}_KEY";
          pskVar = name: "WG_${envName name}_PSK";
          hasPsk = name: profiles.${name}.presharedKey or false;
          extrasFor = name: profiles.${name}.extraSecrets or [ ];
          extraVar = name: extra: "WG_${envName name}_${envName extra}";
        in
        {
          config = lib.mkIf (profiles != { }) {
            sops.secrets = lib.listToAttrs (
              lib.concatMap (
                name:
                [ (lib.nameValuePair (secretFor name) { }) ]
                ++ lib.optional (hasPsk name) (lib.nameValuePair "${secretFor name}-psk" { })
                ++ map (extra: lib.nameValuePair "${secretFor name}-${extra}" { }) (extrasFor name)
              ) profileNames
            );

            sops.templates."wireguard.env".content = lib.concatLines (
              lib.concatMap (
                name:
                [ "${keyVar name}=${config.sops.placeholder.${secretFor name}}" ]
                ++ lib.optional (hasPsk name) "${pskVar name}=${config.sops.placeholder."${secretFor name}-psk"}"
                ++ map (extra: "${extraVar name extra}=${config.sops.placeholder."${secretFor name}-${extra}"}") (
                  extrasFor name
                )
              ) profileNames
            );

            networking.networkmanager.ensureProfiles = {
              environmentFiles = [ config.sops.templates."wireguard.env".path ];

              profiles = lib.mapAttrs (
                name: profile:
                let
                  withKey =
                    lib.recursiveUpdate
                      (removeAttrs profile [
                        "presharedKey"
                        "extraSecrets"
                      ])
                      {
                        wireguard.private-key = "$" + keyVar name;
                      };
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
                if hasPsk name then lib.mapAttrs addPsk withKey else withKey
              ) profiles;
            };
          };
        };
    };
}
