{ config, ... }:
let
  inherit (config) packageSources;
in
{
  den.aspects.lgtv = _: {
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        lua = lib.generators.mkLuaInline;
        systemctl = lib.getExe' pkgs.systemd "systemctl";
      in
      {
        sops.secrets = {
          "lgtv/mac" = { };
        };

        sops.templates."lgtv.env" = {
          owner = "shochraos";
          content = ''
            LGTV_MAC=${config.sops.placeholder."lgtv/mac"}
            LGTV_IP=192.168.30.6
          '';
        };

        systemd.services.wol-lgtv = {
          description = "Wake-on-LAN for LGTV";

          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
            "display-manager.service"
          ];
          wantedBy = [ "graphical.target" ];

          serviceConfig = {
            Type = "oneshot";
            User = "shochraos";
            EnvironmentFile = config.sops.templates."lgtv.env".path;
            ExecStart = "${lib.getExe pkgs.wakeonlan} -i \${LGTV_IP} \${LGTV_MAC}";
          };
        };

        security.sudo.extraRules = [
          {
            users = [ "shochraos" ];
            commands = [
              {
                command = "${systemctl} start wol-lgtv.service";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];

        host.hyprland.keybinds = [
          {
            _args = [
              "SUPER + ALT + Home"
              (lua "hl.dsp.exec_cmd('sudo ${systemctl} start wol-lgtv.service')")
              { locked = true; }
            ];
          }
        ];
      };

    provides.to-users.homeManager =
      {
        lib,
        config,
        osConfig,
        pkgs,
        ...
      }:
      let
        bscpylgtv = pkgs.callPackage packageSources.bscpylgtv { };
      in
      lib.mkIf (config.home.username == "shochraos") {
        systemd.user.services.sol-lgtv = {
          Unit = {
            Description = "Shutdown-On-LAN for LGTV";
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            Type = "oneshot";
            EnvironmentFile = osConfig.sops.templates."lgtv.env".path;
            ExecStart = "${lib.getExe' pkgs.coreutils "true"}";
            RemainAfterExit = true;
            ExecStop = "${lib.getExe bscpylgtv} \${LGTV_IP} power_off";
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };
      };
  };
}
