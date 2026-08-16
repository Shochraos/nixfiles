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
                "CTRL + ALT + H"
                (lua "hl.dsp.exec_cmd('${config.host.flakeDir}/assets/scripts/macro-w-escape-14min.sh')")
              ];
            }
            {
              _args = [
                "CTRL + ALT + P"
                (lua "hl.dsp.exec_cmd('${config.host.flakeDir}/assets/scripts/macro-key-sequence.sh')")
              ];
            }
          ];
        };
    };
}
