{ username, pkgs, ...}:
{
  users.users.${username} = 
  { 
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "networkmanager" ]; 
  };
  
  programs.fish.enable = true;

  home-manager.users.${username} = 
  {
    home.username = username;
    home.homeDirectory = "/home/${username}";
  };
}