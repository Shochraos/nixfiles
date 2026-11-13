{ config, den, ... }:
let
  inherit (config) assets;
in
{
  den.aspects.gaming.includes = with den.aspects; [
    hdr
    (den.batteries.unfree [
      "steam"
      "steam-unwrapped"
      "lsfg-vk"
      "lsfg-vk-ui"
    ])
  ];

  den.aspects.gaming = {
    nixos = {
      services.udev.extraRules = ''
        SUBSYSTEM=="input", ATTRS{idVendor}=="36b0", ATTRS{idProduct}=="3002", ENV{ID_INPUT_JOYSTICK}=="?*", ENV{ID_INPUT_JOYSTICK}=""
        SUBSYSTEM=="input", ATTRS{idVendor}=="36b0", ATTRS{idProduct}=="3002", KERNEL=="js[0-9]*", MODE="0000", ENV{ID_INPUT_JOYSTICK}=""
      '';
    };

    provides.to-users.homeManager =
      { pkgs, ... }:
      let
        irony-mod-manager = pkgs.callPackage config.packageSources.ironyModManager { };
      in
      {
        home.packages = with pkgs; [
          amethyst-mod-manager
          samrewritten
          irony-mod-manager
          lsfg-vk
          lsfg-vk-ui
        ];

        xdg.desktopEntries = {
          samrewritten = {
            name = "SamRewritten";
            exec = "samrewritten %U";
            terminal = false;
            icon = "${assets.samrewrittenIcon}";
          };

          ironymodmanager = {
            name = "IronyModManager";
            exec = "IronyModManager";
            terminal = false;
            startupNotify = false;
            icon = "${assets.ironyModManagerIcon}";
          };
        };
      };
  };
}
