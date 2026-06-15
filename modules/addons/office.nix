{
  aspects.home.office =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        libreoffice-qt-fresh
        pdfarranger
      ];
    };
}
