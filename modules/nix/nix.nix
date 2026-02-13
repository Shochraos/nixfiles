{ username, ... }:
{
  nix = 
  {
    settings.experimental-features = [ "nix-command" "flakes"];
    settings.download-buffer-size = 524288000;
  };
  
  nixpkgs.config.allowUnfree = true;
  
  system.stateVersion = "25.05";
  
  home-manager.users.${username} = 
  {
    home.stateVersion = "25.05";
  };
}