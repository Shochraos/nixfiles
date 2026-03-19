{ inputs, username, pkgs, ... }:
{
  home-manager.users.${username} =
  {
    imports = [  inputs.spicetify-nix.homeManagerModules.default ];
    home.packages = with pkgs; 
    [ 
      (discord.override { withVencord = true; }) 
      anki  
    ];
    
    programs.spicetify = 
    {
      enable = true;
    };
  };
}