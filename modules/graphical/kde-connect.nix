{
  den.aspects.kde-connect.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.valent ];
      hardware.uinput.enable = true;

      host.network.homeOnlyPorts = {
        tcp.ranges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
        udp.ranges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
      };
    };

  den.aspects.kde-connect.provides.to-users.homeManager =
    { lib, pkgs, ... }:
    {
      xdg.configFile."autostart/ca.andyholmes.Valent-autostart.desktop".text = ''
        [Desktop Entry]
        Hidden=true
      '';

      systemd.user.services.valent = {
        Unit = {
          Description = "Valent (KDE Connect Implementation)";
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${lib.getExe pkgs.valent} --gapplication-service";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };

      wayland.windowManager.hyprland.extraConfig = ''
        hl.on("hyprland.start", function()
          hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_RUNTIME_DIR DISPLAY && systemctl --user restart valent")
        end)
      '';
    };
}
