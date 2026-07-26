{ inputs, ... }:
{
  den.aspects.apps =
    { host, ... }:
    {
      provides.to-users.homeManager =
        {
          lib,
          pkgs,
          osConfig,
          ...
        }:
        {
          imports = [ inputs.spicetify-nix.homeManagerModules.default ];

          home.packages = with pkgs; [
            (discord.override { withVencord = true; })
            anki
            libreoffice-qt-fresh
            pdfarranger
          ];

          programs.spicetify =
            let
              spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
              matugenScheme = ../../configs/matugen/spicetify-${host.name}.json;
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
