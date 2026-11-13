{ den, ... }:
{
  den.aspects.apps = {
    provides.to-users.homeManager =
      {
        pkgs,
        osConfig,
        ...
      }:
      let
        spotifastPkg = pkgs.spotifast;
      in
      {
        home.packages = [
          spotifastPkg
          #pkgs.libreoffice-qt-stable
          pkgs.pdfarranger
          pkgs.kdePackages.filelight
        ];

        home.file = {
          ".local/share/fonts/NotoSansCJK-Regular.ttc".source =
            "${pkgs.noto-fonts-cjk-sans}/share/fonts/opentype/noto-cjk/NotoSansCJK-Regular.ttc";
        };

        xdg.autostart.entries =
          let
            desktopEntries = {
              spotifast = "${spotifastPkg}/share/applications/spotifast.desktop";
            };
          in
          map (name: desktopEntries.${name}) (
            builtins.filter (name: desktopEntries ? ${name}) osConfig.host.autostart
          );

      };
  };
}
