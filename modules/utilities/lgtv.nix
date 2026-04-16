{ pkgs, username, ... }:
{
  environment.systemPackages = with pkgs; [ wakeonlan ];

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
      ExecStart = "${pkgs.wakeonlan}/bin/wakeonlan wakeonlan -i 192.168.30.6 60:45:e8:1e:b5:40";
    };
  };

  security.sudo.extraRules = [
    {
      users = [ "shochraos" ];
      commands = [
        {
          command = "${pkgs.systemd}/bin/systemctl start wol-lgtv.service";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  home-manager.users.${username} = {
    systemd.user.services.sol-lgtv = {
      Unit = {
        Description = "Shutdown-On-LAN for LGTV";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/true";
        RemainAfterExit = true;
        WorkingDirectory = "/home/${username}/Applications/bscpylgtv";
        ExecStop = "${pkgs.direnv}/bin/direnv exec /home/${username}/Applications/bscpylgtv bscpylgtvcommand 192.168.30.6 power_off";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    wayland.windowManager.hyprland = {
      settings = {
        bindl = [
          "$mod ALT, Home, exec, sudo ${pkgs.systemd}/bin/systemctl start wol-lgtv.service"
        ];
      };
    };
  };
}
