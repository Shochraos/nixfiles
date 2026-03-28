{ username, inputs, pkgs, ... }:
{
  boot.kernelModules = [ "ntsync" ];
  
  nixpkgs.overlays = [ inputs.millennium.overlays.default ];
  programs.steam =
  {
    enable = true;
    package = pkgs.millennium-steam;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };
  
  home-manager.users.${username} =
  {
    home.sessionVariables =
    {
      PROTON_ENABLE_WAYLAND = "1";
      PROTON_USE_NTSYNC = "1";
      PROTON_DLSS_UPGRADE = "1";
    };
    
    xdg.autostart = 
    {
      entries = 
      [
        "${pkgs.steam}/share/applications/steam.desktop"
      ];
    };
  };
}