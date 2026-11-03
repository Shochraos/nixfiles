{
  config,
  lib,
  ...
}:
let
  inherit (config) assets;
in
{
  den.aspects.wifi.nixos =
    { config, ... }:
    let
      profiles = config.host.wifi.profiles;
      profileNames = builtins.attrNames profiles;
      secretFor = name: "wifi/${name}";
      envName = name: lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] name);
      isOpen = name: profiles.${name}.open;
      isEap = name: profiles.${name}.eap;
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
        }) profiles.${name}.extraSecrets;
      secretEntries = builtins.concatMap secretsFor profileNames;
      secrets = map (entry: entry.secret) secretEntries;
      variables = map (entry: entry.var) secretEntries;
    in
    {
      config = lib.mkIf (profiles != { }) {
        assertions = [
          {
            assertion = builtins.length secrets == builtins.length (lib.unique secrets);
            message = "host.wifi.profiles: generated secret identifiers collide.";
          }
          {
            assertion = builtins.length variables == builtins.length (lib.unique variables);
            message = "host.wifi.profiles: profile names or extraSecrets collide after environment-variable normalization.";
          }
        ];

        environment.etc."eduroam-certs/hs-fulda-eduroam-ca.pem".source = assets.hsFuldaEduroamCa;

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
