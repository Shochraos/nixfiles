  { pkgs, username, ... }:
  {
    home-manager.users.${username} =
    {
      fonts.fontconfig.enable = true;
  
      home.packages = with pkgs; [ nerd-fonts.fira-code ];
    };
  }