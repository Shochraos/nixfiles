{ username, pkgs, ... }:
{
  home-manager.users.${username} =
  {
    home.packages = with pkgs;
    [
      samrewritten
      faugus-launcher
    ];
    
    xdg.desktopEntires = 
    {
      samrewritten =
      {
        name = "SamRewritten";
        exec = "samrewritten %U";
        terminal = false;
        icon = "${../../assets/icons/samrewritten.png}";
      };
      
      ironymodmanager =
      {
        name = "IronyModManager";
        exec = "direnv exec /home/${username}/Applications/ironymodmanager/IronyModManager";
        terminal = false;
        startupNotify = false;
        icon = "${../../assets/icons/ironymodmanager.png}";
      };
    };
  };
}