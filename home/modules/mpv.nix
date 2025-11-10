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
}