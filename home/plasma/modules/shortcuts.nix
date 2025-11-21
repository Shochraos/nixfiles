{ lib, isAzazel, ... }:
{
  programs.plasma =
  {
    shortcuts = lib.mkMerge
    [
    {
      kwin = 
      {
        "Switch One Desktop to the Left" = ["Ctrl+T" "Meta+Ctrl+Left"];
        "Switch One Desktop to the Right" = ["Ctrl+W" "Meta+Ctrl+Right"];
      };

      mediacontrol =
      {
        mediavolumedown = "F11";
        mediavolumeup = "F12";
      };
      "services/org.kde.dolphin.desktop"._launch = "Meta+F";
      "services/com.mitchellh.ghostty.desktop"._launch = "Meta+T";         
    }
    (lib.mkIf isAzazel 
    {
      "services/gamechat_chat.desktop"._launch = "Volume Down";
      "services/gamechat_game.desktop"._launch = "Volume Up";
      "services/gamechat_reset.desktop"._launch = "Ctrl+Shift+D";
    })
    ];
  };
}