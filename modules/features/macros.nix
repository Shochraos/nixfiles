{
  den.aspects.macros =
    { user, ... }:
    {
      nixos =
        {
          config,
          lib,
          ...
        }:
        let
          lua = lib.generators.mkLuaInline;
        in
        {
          programs.ydotool.enable = true;

          users.groups.ydotool.members = [ user.name ];

          host.hyprland.keybinds = [
            {
              _args = [
                "CTRL + ALT + R"
                (lua "hl.dsp.exec_cmd('${config.host.flakeDir}/assets/scripts/macro-w-escape.sh')")
              ];
            }
          ];
        };
    };
}
