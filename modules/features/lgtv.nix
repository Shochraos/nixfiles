{
  den.aspects.lgtv =
    { user, ... }:
    {
      nixos =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        let
          lua = lib.generators.mkLuaInline;
        in
        {
          environment.systemPackages = with pkgs; [ wakeonlan ];

          sops.secrets = {
            "lgtv/mac" = { };
            "lgtv/ip" = { };
          };

          sops.templates."lgtv.env" = {
            owner = user.name;
            content = ''
              LGTV_MAC=${config.sops.placeholder."lgtv/mac"}
              LGTV_IP=${config.sops.placeholder."lgtv/ip"}
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
              EnvironmentFile = config.sops.templates."lgtv.env".path;
              ExecStart = "${pkgs.wakeonlan}/bin/wakeonlan -i \${LGTV_IP} \${LGTV_MAC}";
            };
          };

          security.sudo.extraRules = [
            {
              users = [ user.name ];
              commands = [
                {
                  command = "${pkgs.systemd}/bin/systemctl start wol-lgtv.service";
                  options = [ "NOPASSWD" ];
                }
              ];
            }
          ];

          host.hyprland.keybinds = [
            {
              _args = [
                "SUPER + ALT + Home"
                (lua "hl.dsp.exec_cmd('sudo ${pkgs.systemd}/bin/systemctl start wol-lgtv.service')")
                { locked = true; }
              ];
            }
          ];
        };

      provides.to-users.homeManager =
        { osConfig, pkgs, ... }:
        {
          systemd.user.services.sol-lgtv = {
            Unit = {
              Description = "Shutdown-On-LAN for LGTV";
              PartOf = [ "graphical-session.target" ];
            };
            Service = {
              Type = "oneshot";
              EnvironmentFile = osConfig.sops.templates."lgtv.env".path;
              ExecStart = "${pkgs.coreutils}/bin/true";
              RemainAfterExit = true;
              WorkingDirectory = "/home/${user.name}/Applications/bscpylgtv";
              ExecStop = "${pkgs.direnv}/bin/direnv exec /home/${user.name}/Applications/bscpylgtv bscpylgtvcommand \${LGTV_IP} power_off";
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };
        };
    };
}
