{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;

    # MPV config
    config ={
      vo = "gpu-next";
    };

    scripts = with pkgs; [
      mpvScripts.evafast
      mpvScripts.uosc
    ];

    #scriptOpts = {
    #  osc = {
       # scalewindowed = 2.0;
       # vidscale = false;
       # visibility = "always";
     # };
    #};
  };

  xdg.configFile."jellyfin-mpv-shim/conf.json".source = ../../configs/jellyfin-mpv-shim/conf.json;
}