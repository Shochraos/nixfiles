{ lib, username, pkgs, ... }:
{
  nix = 
  {
    extraOptions = lib.lists.remove "" (lib.strings.splitString "\n" (builtins.readFile ../../local/devenv.txt));
  };
  
  home-manager.users.${username} =
  {
    home.packages = with pkgs; 
    [
      anki  
      devenv
    ];
  };
}