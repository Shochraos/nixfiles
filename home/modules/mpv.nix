{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;
    config = {
      "vo" = "gpu-next";
    };
  };
}