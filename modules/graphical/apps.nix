{ inputs, ... }:
{
  den.aspects.apps = _: {
    provides.to-users.homeManager =
      {
        pkgs,
        osConfig,
        ...
      }:
      let
        discordPkg = pkgs.discord.override { withEquicord = true; };
        spotifastPkg = inputs.spotifast.packages.${pkgs.stdenv.hostPlatform.system}.spotifast;
      in
      {
        home.packages = [
          discordPkg
          spotifastPkg
          pkgs.libreoffice-qt-stable
          pkgs.pdfarranger
        ];

        home.file = {
          ".local/share/fonts/NotoSansCJK-VF.otf.ttc".source =
            "${pkgs.noto-fonts-cjk-sans}/share/fonts/opentype/noto-cjk/NotoSansCJK-VF.otf.ttc";
          ".local/share/fonts/NotoSansMonoCJK-VF.otf.ttc".source =
            "${pkgs.noto-fonts-cjk-sans}/share/fonts/opentype/noto-cjk/NotoSansMonoCJK-VF.otf.ttc";
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
