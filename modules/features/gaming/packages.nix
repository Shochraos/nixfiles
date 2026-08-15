{ config, ... }:
let
  inherit (config) assets;

  ironyModManagerOverlay = final: _prev: {
    irony-mod-manager = final.callPackage config.packageSources.ironyModManager { };
  };
in
{
  den.aspects.gaming = {
    nixos = {
      nixpkgs.overlays = [ ironyModManagerOverlay ];

      services.udev.extraRules = ''
        SUBSYSTEM=="input", ATTRS{idVendor}=="36b0", ATTRS{idProduct}=="3002", ENV{ID_INPUT_JOYSTICK}=="?*", ENV{ID_INPUT_JOYSTICK}=""
        SUBSYSTEM=="input", ATTRS{idVendor}=="36b0", ATTRS{idProduct}=="3002", KERNEL=="js[0-9]*", MODE="0000", ENV{ID_INPUT_JOYSTICK}=""
      '';
    };

    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          samrewritten
          faugus-launcher
          irony-mod-manager
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
