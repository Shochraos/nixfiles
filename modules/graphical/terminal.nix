{
  den.aspects.terminal.provides.to-users.homeManager =
    { osConfig, pkgs, ... }:
    {
      home.packages = [ pkgs.libnotify ];

      programs.herdr = {
        enable = true;
        settings = {
          onboarding = false;
          theme.name = "terminal";
          terminal.shell_mode = "login";
          update.version_check = false;
          ui = {
            sound.enabled = false;
            toast.delivery = "system";
            sidebar.agents.rows = [
              [
                "state_icon"
                "workspace"
                "tab"
              ]
              [
                "agent"
                "terminal_title_stripped"
              ]
            ];
          };
        };
      };

      xdg.configFile."herdr/config.toml".force = true;

      programs.ghostty = {
        enable = true;
        settings = {
          background = "000000";
          background-opacity = 0.5;
          background-blur = true;
          font-family = osConfig.stylix.fonts.monospace.name;
          font-size = osConfig.stylix.fonts.sizes.terminal;
        };
      };

      wayland.windowManager.hyprland.extraConfig = ''
        hl.on("hyprland.start", function()
          hl.exec_cmd("ghostty -e herdr", { workspace = "2" })
        end)
      '';
    };
}
