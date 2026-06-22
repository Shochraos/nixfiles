{
  aspects.nixos.gaming =
    { pkgs, username, ... }:
    let
      moondeck = pkgs.callPackage ../../packages/moondeck-buddy { };
    in
    {
      services.sunshine = {
        enable = true;
        package = pkgs.sunshine.override {
          cudaSupport = true;
          cudaPackages = pkgs.cudaPackages;
        };
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;

        applications = {
          env = {
            PATH = "$(PATH):/run/current-system/sw/bin:/etc/profiles/per-user/${username}/bin:$(HOME)/.local/bin";
          };
          apps = [
            {
              name = "MoonDeckStream";
              cmd = "${moondeck}/bin/MoonDeckStream";
              exclude-global-prep-cmd = "false";
              elevated = "false";
            }
          ];
        };

        settings = {
          "nvenc_preset" = 7;
          "nvenc_twopass" = "full_res";
          "nvenc_spatial_aq" = "enabled";
        };
      };

      networking.firewall.allowedTCPPorts = [ 59999 ];
    };

  aspects.home.gaming =
    { pkgs, ... }:
    let
      moondeck = pkgs.callPackage ../../packages/moondeck-buddy { };
    in
    {
      home.packages = [ moondeck ];
      xdg.autostart.entries = [ "${moondeck}/share/applications/MoonDeckBuddy.desktop" ];
    };
}
