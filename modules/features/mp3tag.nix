{
  den.aspects.mp3tag.provides.to-users.homeManager =
    { config, ... }:
    {
      xdg.desktopEntries = {
        mp3tag = {
          name = "MP3Tag";
          exec = "direnv exec ${config.home.homeDirectory}/Applications/mp3tag wine ${config.home.homeDirectory}/Applications/mp3tag/mp3tag.exe";
          terminal = false;
          startupNotify = false;
          icon = "${../../assets/icons/mp3tag.png}";
        };
      };
    };
}
