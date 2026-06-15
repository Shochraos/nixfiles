{
  aspects.inputremapper =
    { username, pkgs, ... }:
    {
      services.input-remapper = {
        enable = true;
        enableUdevRules = true;
      };
      home-manager.users.${username} = {
        xdg.autostart = {
          entries = [
            "${pkgs.input-remapper}/share/applications/input-remapper-autoload.desktop"
          ];
        };
      };
    };
}
