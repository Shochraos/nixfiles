{
  den.aspects.mp3tag =
    { user, ... }:
    {
      provides.to-users.homeManager = {
        xdg.desktopEntries = {
          mp3tag = {
            name = "MP3Tag";
            exec = "direnv exec /home/${user.name}/Applications/mp3tag wine /home/${user.name}/Applications/mp3tag/mp3tag.exe";
            terminal = false;
            startupNotify = false;
            icon = "${../../assets/icons/mp3tag.png}";
          };
        };
      };
    };
}
