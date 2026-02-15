{ username, pkgs, ... }:
{
  home-manager.users.${username} =
  {
    home.packages = with pkgs; 
    [ 
      (discord.override { withVencord = true; }) 
      spotify
    ];
  };
}