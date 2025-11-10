{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.name  = "Shochraos";
      user.email = "github@shonline.slmail.me";
    };
  };
}