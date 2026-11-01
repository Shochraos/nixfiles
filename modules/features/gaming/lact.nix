{
  den.aspects.gaming.nixos =
    { config, pkgs, ... }:
    let
      settings = {
        version = 7;
        apply_settings_timer = 5;
        auto_switch_profiles = false;
        current_profile = null;

        daemon = {
          log_level = "info";
          admin_group = "wheel";
          disable_clocks_cleanup = false;
        };

        gpus = config.host.lact.gpus;
      };
      quotedKeyYaml = (pkgs.formats.yaml { }).generate "lact-config-quoted-keys.yaml" settings;

      configFile = pkgs.runCommand "lact-config.yaml" { } ''
        sed -E "s/^([[:space:]]*)'([0-9]+)':/\1\2:/" ${quotedKeyYaml} > $out
        if grep -qE "^[[:space:]]*'[0-9]+':" $out; then
          echo "lact deserializes these maps with integer keys; one was left quoted" >&2
          exit 1
        fi
      '';
    in
    {
      services.lact.enable = true;

      environment.etc."lact/config.yaml".source = configFile;
      systemd.services.lactd.restartTriggers = [ configFile ];
    };
}
