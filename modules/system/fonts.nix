{
  den.aspects.fonts.nixos =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
      ];
    };

  den.aspects.fonts.provides.to-users.homeManager = {
    fonts.fontconfig.enable = true;
  };
}
