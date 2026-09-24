{ inputs, config, ... }:
let
  inherit (config) assets;
in
{
  den.aspects.apps =
    { host, ... }:
    {
      provides.to-users.homeManager =
        {
          lib,
          config,
          pkgs,
          osConfig,
          ...
        }:
        {
          imports = [ inputs.spicetify-nix.homeManagerModules.default ];

          home.packages = with pkgs; [
            (discord.override { withVencord = true; })
            libreoffice-qt-stable
            pdfarranger
          ];

          xdg.autostart.entries =
            let
              desktopEntries = {
                discord = "${pkgs.discord.override { withVencord = true; }}/share/applications/discord.desktop";
                spotify = "${config.programs.spicetify.spicedSpotify}/share/applications/spotify.desktop";
              };
            in
            map (name: desktopEntries.${name}) osConfig.host.autostart;

          programs.spicetify =
            let
              spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
              matugenScheme = assets.matugenSchemes + "/spicetify-${host.name}.json";
            in
            {
              enable = true;
              theme = spicePkgs.themes.sleek;
              enabledSnippets = [
                ''
                  html, body, #main, .Root, [class*="encore-"] {
                      font-family: '${osConfig.stylix.fonts.sansSerif.name}', sans-serif !important;
                  }

                  .encore-icon, .icon, svg {
                      font-family: unset !important;
                  }
                ''
              ];
              customColorScheme = lib.optionalAttrs (builtins.pathExists matugenScheme) (
                builtins.fromJSON (builtins.readFile matugenScheme)
              );
            };
        };
    };
}
