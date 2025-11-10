{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;

    # MPV config
    config ={
      vo = "gpu-next";
    };

    # MPV scripts
    scripts = with pkgs; [
      mpvScripts.evafast
      mpvScripts.uosc
    ];

    # MPV script options
    #scriptOpts = {
    #  osc = {
       # scalewindowed = 2.0;
       # vidscale = false;
       # visibility = "always";
     # };
    #};
  };

  # Jellyfin MPV Shim config to use external mpv
  xdg.configFile."jellyfin-mpv-shim/conf.json".source = ../../configs/jellyfin-mpv-shim/conf.json;
}