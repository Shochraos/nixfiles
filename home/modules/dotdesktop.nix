{ config, ... }:
{
  xdg.desktopEntries =
  {
    samrewritten =
    {
      name = "SamRewritten";
      exec = "samrewritten %U";
      terminal = false;
      icon = "${../../assets/icons/samrewritten.png}";
      categories = [ "X-Games" ];
    };
    
    "gamechat_chat" = 
    {
      name = "gamechat_chat";
      exec = "${config.home.homeDirectory}/Scripts/Pipewire/gamechat_chat.sh";
      terminal = false;
      startupNotify = false;
      noDisplay = true;
    };
    
    "gamechat_game" = 
    {
      name = "gamechat_game";
      exec = "${config.home.homeDirectory}/Scripts/Pipewire/gamechat_game.sh";
      terminal = false;
      startupNotify = false;
      noDisplay = true;
    };
    
    "gamechat_reset" = 
    {
      name = "gamechat_reset";
      exec = "${config.home.homeDirectory}/Scripts/Pipewire/gamechat_reset.sh";
      terminal = false;
      startupNotify = false;
      noDisplay = true;
    };
  };
}