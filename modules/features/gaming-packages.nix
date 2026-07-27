{
  den.aspects.gaming = {
    nixos = {
      services.udev.extraRules = ''
        SUBSYSTEM=="input", ATTRS{idVendor}=="36b0", ATTRS{idProduct}=="3002", ENV{ID_INPUT_JOYSTICK}=="?*", ENV{ID_INPUT_JOYSTICK}=""
        SUBSYSTEM=="input", ATTRS{idVendor}=="36b0", ATTRS{idProduct}=="3002", KERNEL=="js[0-9]*", MODE="0000", ENV{ID_INPUT_JOYSTICK}=""
      '';
    };

    provides.to-users.homeManager =
      { config, pkgs, ... }:
      {
        home.packages = with pkgs; [
          samrewritten
          faugus-launcher
        ];

        xdg.desktopEntries = {
          samrewritten = {
            name = "SamRewritten";
            exec = "samrewritten %U";
            terminal = false;
            icon = "${../../assets/icons/samrewritten.png}";
          };

          ironymodmanager = {
            name = "IronyModManager";
            exec = "direnv exec ${config.home.homeDirectory}/Applications/ironymodmanager/IronyModManager";
            terminal = false;
            startupNotify = false;
            icon = "${../../assets/icons/ironymodmanager.png}";
          };
        };
      };
  };
}
