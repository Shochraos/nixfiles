  { pkgs, ... }:
  {
    # Fontconfig
    fonts.fontconfig.enable = true;

    # Fonts
    home.packages = with pkgs; [
        jetbrains-mono
        nerd-fonts.fira-code
    ];
  }
