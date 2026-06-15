{
  aspects.nixos.inputremapper = {
    services.input-remapper = {
      enable = true;
      enableUdevRules = true;
    };
  };

  aspects.home.inputremapper =
    { pkgs, ... }:
    {
      xdg.autostart = {
        entries = [
          "${pkgs.input-remapper}/share/applications/input-remapper-autoload.desktop"
        ];
      };
    };
}
