{
  aspects.home.apps =
    { inputs, pkgs, systemname, ... }:
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.default ];

      home.packages = with pkgs; [
        (discord.override { withVencord = true; })
        anki
        claude-code
        libreoffice-qt-fresh
        pdfarranger
      ];

      programs.spicetify =
        let
          spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
        in
        {
          enable = true;
          theme = spicePkgs.themes.sleek;
          enabledSnippets = [
            ''
              html, body, #main, .Root, [class*="encore-"] {
                  font-family: 'Overpass', sans-serif !important;
              }

              .encore-icon, .icon, svg {
                  font-family: unset !important;
              }
            ''
          ];
          customColorScheme = builtins.fromJSON (builtins.readFile ../../configs/matugen/spicetify-${systemname}.json);
        };
    };
}
