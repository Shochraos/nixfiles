_: {
  den.aspects.apps = _: {
    provides.to-users.homeManager =
      {
        pkgs,
        osConfig,
        ...
      }:
      let
        discordPkg = pkgs.discord.override { withEquicord = true; };
        spotifastPkg = pkgs.spotifast;
      in
      {
        home.packages = [
          discordPkg
          spotifastPkg
          pkgs.libreoffice-qt-stable
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
              discord = "${discordPkg}/share/applications/discord.desktop";
              spotifast = "${spotifastPkg}/share/applications/spotifast.desktop";
            };
          in
          map (name: desktopEntries.${name}) (
            builtins.filter (name: desktopEntries ? ${name}) osConfig.host.autostart
          );

      };
  };
}
