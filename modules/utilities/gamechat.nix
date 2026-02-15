{ pkgs, username, ... }:
{
  services.pipewire.pulse.enable = true;
  environment.systemPackages = with pkgs; [ pulseaudio ];
  
  home-manager.users.${username} =
  {
    xdg.desktopEntries =
    {
      "gamechat_chat" =
      {
        name = "gamechat_chat";
        exec = "/home/${username}/Scripts/Pipewire/gamechat_chat.sh";
        terminal = false;
        startupNotify = false;
        noDisplay = true;
      };
  
      "gamechat_game" =
      {
        name = "gamechat_game";
        exec = "/home/${username}/Scripts/Pipewire/gamechat_game.sh";
        terminal = false;
        startupNotify = false;
        noDisplay = true;
      };
  
      "gamechat_reset" =
      {
        name = "gamechat_reset";
        exec = "/home/${username}/Scripts/Pipewire/gamechat_reset.sh";
        terminal = false;
        startupNotify = false;
        noDisplay = true;
      };
    };
    
    programs.plasma = 
    {
      shortcuts =
      {
        "services/gamechat_chat.desktop"._launch = "Volume Down";
        "services/gamechat_game.desktop"._launch = "Volume Up";
        "services/gamechat_reset.desktop"._launch = "Ctrl+Shift+D";
      };
    };
  };
}