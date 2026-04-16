{ pkgs, username, ... }:
{
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
  ];

  home-manager.users.${username} = {
    fonts.fontconfig.enable = true;
  };
}
