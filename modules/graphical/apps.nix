{ den, ... }:
{
  den.aspects.apps = {
    includes = [
      (den.batteries.unfree [
        "discord"
        "discord-unwrapped"
      ])
    ];

    provides.to-users.homeManager =
      {
        pkgs,
        osConfig,
        ...
      }:
      let
        discordPkg = pkgs.discord.override {
          withEquicord = true;
          equicord = pkgs.equicord.overrideAttrs (
            finalAttrs: previousAttrs: {
              version = "2026-11-07";
              src = pkgs.fetchFromGitHub {
                owner = "Equicord";
                repo = "Equicord";
                tag = finalAttrs.version;
                hash = "sha256-y48T5X5sMvGDU3Wp7+5U2kQcBacbeTQMJ4FryXJDe6w=";
              };
              pnpmDeps = previousAttrs.pnpmDeps.overrideAttrs {
                outputHash = "sha256-YI+fviBbfyKPdPZtMqin3Sk2M1Rumdf+B8n68bsibnc=";
              };
            }
          );
        };
        spotifastPkg = pkgs.spotifast;
      in
      {
        home.packages = [
          discordPkg
          spotifastPkg
          pkgs.libreoffice-qt-stable
          pkgs.pdfarranger
          pkgs.kdePackages.filelight
        ]
        ++ pkgs.lib.optional (osConfig.networking.hostName != "Azazel") pkgs.tutanota-desktop;

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
