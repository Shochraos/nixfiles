{ username, ... }:
{
  home-manager.users.${username} =
  {
    xdg.desktopEntries =
    {
      mp3tag =
      {
        name = "MP3Tag";
        exec = "direnv exec /home/${username}/Applications/mp3tag wine /home/${username}/Applications/mp3tag/mp3tag.exe";
        terminal = false;
        startupNotify = false;
        icon = "${../../assets/icons/mp3tag.png}";
      };
    };
  };
}