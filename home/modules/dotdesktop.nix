{ pkgs, ... }:
{
  xdg.desktopEntries = {
    samrewritten = {
      name = "SamRewritten";
      exec = "samrewritten %U";
      terminal = false;
      icon = "${../../assets/icons/samrewritten.png}";
      categories = [ "X-Games" ];
    };
  };
}