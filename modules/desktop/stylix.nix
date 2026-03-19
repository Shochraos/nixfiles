{ pkgs, config, username, ... }:
{
  stylix = 
  {
    enable = true;
    #base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    base16Scheme = ../../assets/themes/metro.yaml;
    
    cursor = 
    {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
    
    fonts = 
    {
      serif = config.stylix.fonts.sansSerif;
  
      sansSerif = 
      {
        package = pkgs.overpass;
        name = "Overpass";
      };
  
      monospace = 
      {
        package = pkgs.nerd-fonts.overpass;
        name = "Nerd Fonts Overpass Mono";
      };
  
      emoji = 
      {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
  
  programs.dconf.enable = true;
  
  home-manager.users.${username} = 
  {
    stylix.targets.zen-browser.profileNames = [ "Nix-Zen" ];
    
    stylix.targets.mangohud.enable = false;
    stylix.targets.starship.enable = false;
  };
}