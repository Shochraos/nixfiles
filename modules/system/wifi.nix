{
  den.aspects.wifi.nixos =
    {
      config,
      lib,
      ...
    }:
    let
      profiles = config.host.wifi.profiles;
      profileNames = builtins.attrNames profiles;
      secretFor = name: "wifi/${name}";
      envName = name: lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] name);
      isOpen = name: profiles.${name}.open or false;
      isEap = name: profiles.${name}.eap or false;
      secretVar = name: "WIFI_${envName name}_${if isEap name then "PASSWORD" else "PSK"}";
      secretsFor =
        name:
        lib.optional (!isOpen name) {
          secret = secretFor name;
          var = secretVar name;
        }
        ++ map (extra: {
          secret = "${secretFor name}-${extra}";
          var = "WIFI_${envName name}_${envName extra}";
        }) (profiles.${name}.extraSecrets or [ ]);
      secretEntries = builtins.concatMap secretsFor profileNames;
    in
    {
      config = lib.mkIf (profiles != { }) {
        sops.secrets = builtins.listToAttrs (map (e: lib.nameValuePair e.secret { }) secretEntries);

        sops.templates."wifi.env".content = lib.concatLines (
          map (e: "${e.var}=${config.sops.placeholder.${e.secret}}") secretEntries
        );

        networking.networkmanager.ensureProfiles = {
          environmentFiles = lib.mkIf (secretEntries != [ ]) [ config.sops.templates."wifi.env".path ];

          profiles = builtins.mapAttrs (
            name: profile:
            let
              defaults = {
                connection = {
                  id = name;
                  type = "wifi";
                };
                wifi = {
                  ssid = name;
                  mode = "infrastructure";
                };
              }
              // lib.optionalAttrs (!isOpen name) {
                wifi-security.key-mgmt = if isEap name then "wpa-eap" else "wpa-psk";
              };
              withDefaults = lib.recursiveUpdate defaults (
                removeAttrs profile [
                  "open"
                  "eap"
                  "extraSecrets"
                ]
              );
              secret =
                if isOpen name then
                  { }
                else if isEap name then
                  { "802-1x".password = "$" + secretVar name; }
                else
                  { wifi-security.psk = "$" + secretVar name; };
            in
            lib.recursiveUpdate withDefaults secret
          ) profiles;
        };
      };
    };
}
