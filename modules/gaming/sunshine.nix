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
  };

  home-manager.users.${username} = {
    home.packages = [ moondeck ];
    xdg.autostart.entries = [ "${moondeck}/share/applications/MoonDeckBuddy.desktop" ];
  };
  
  networking.firewall.allowedTCPPorts = [ 59999 ];
}
