{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;

    # MPV config
    config ={
      # Video
      vo = "gpu-next";

      # OSD
      osd-font="Jetbrains Mono";
    };

    # MPV scripts
    scripts = with pkgs; [
      mpvScripts.evafast
      mpvScripts.uosc
    ];

    # MPV script options
    scriptOpts = {
      uosc = {
        # Controls
        controls="menu,gap:0.5,<has_many_video>video,<has_many_audio>audio,<video,audio>subtitles,space,play-pause,space,<video,audio>gap:1.0,<has_many_audio>gap:1.0,<has_many_video>gap:1.0,gap:0.5,fullscreen";
        controls_size=50;

        # Font
        font_scale=1.5;
        font_bold=true;
      };
    };
  };

  # Jellyfin-mpv-shim config to use external mpv
  xdg.configFile."jellyfin-mpv-shim/conf.json".source = ../../configs/jellyfin-mpv-shim/conf.json;
}