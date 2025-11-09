{ pkgs, ... }:
{
  xdg.desktopEntries = {
    samrewritten = {
      name = "SamRewritten";
      exec = "samrewritten %U";
      terminal = false;
      icon = "samrewritten";
      categories = [ "X-Games" ];
    };
  };
}