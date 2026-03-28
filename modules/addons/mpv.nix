{ pkgs, username, ... }:
{
  home-manager.users.${username} =
  {
    home.packages = with pkgs; [ jellyfin-mpv-shim ];
    
    programs.mpv =
    {
      enable = true;
  
      config ={
        vo = "gpu-next";
      };
  
      scripts = with pkgs;
      [
        mpvScripts.uosc
      ];

      scriptOpts =
      {
        uosc =
        {
          controls="menu,gap:0.5,<has_many_video>video,<has_many_audio>audio,<video,audio>subtitles,space,play-pause,space,<video,audio>gap:1.0,<has_many_audio>gap:1.0,<has_many_video>gap:1.0,gap:0.5,fullscreen";
          controls_size=50;
  
          font_scale=1.5;
          font_bold=true;
        };
      };
    };
  
    xdg.autostart = 
    {
      entries = 
      [
        "${pkgs.jellyfin-mpv-shim}/share/applications/jellyfin-mpv-shim.desktop"
      ];
    };
    
    xdg.configFile."jellyfin-mpv-shim/conf.json".source = ../../configs/jellyfin-mpv-shim/conf.json;
  };
}