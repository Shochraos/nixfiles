let
  gpuId = "10DE:2684-1458:40E4-0000:01:00.0";

  settings = {
    version = 6;
    apply_settings_timer = 5;
    auto_switch_profiles = false;
    current_profile = null;

    daemon = {
      log_level = "info";
      admin_group = "wheel";
      disable_clocks_cleanup = false;
    };

    gpus.${gpuId} = {
      fan_control_enabled = true;
      fan_control_settings = {
        mode = "curve";
        static_speed = 0.3;
        temperature_key = "edge";
        interval_ms = 500;
        spindown_delay_ms = 5000;
        change_threshold = 5;
        auto_threshold = 50;
        curve = {
          "40" = 0.3;
          "60" = 0.35;
          "70" = 0.4;
          "80" = 0.6;
          "85" = 1.0;
        };
      };
    };
  };
in
{
  den.aspects.gaming.nixos =
    { pkgs, ... }:
    let
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
