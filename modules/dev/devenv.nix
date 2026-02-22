{ lib, username, pkgs, ... }:
{
  nix = 
  {
    extraOptions = ''
      extra-substituters = https://devenv.cachix.org
      extra-trusted-public-keys = ${lib.removeSuffix "\n" (builtins.readFile ../../local/devenv.txt)}
    '';
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