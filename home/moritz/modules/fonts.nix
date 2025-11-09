  { pkgs, ... }:
  {
    home.packages = with pkgs; [
        jetbrains-mono
        nerd-fonts.fira-code
    ];
  }
