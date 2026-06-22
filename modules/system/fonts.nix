{
  aspects.nixos.fonts =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
      ];
    };

  aspects.home.fonts = {
    fonts.fontconfig.enable = true;
  };
}
