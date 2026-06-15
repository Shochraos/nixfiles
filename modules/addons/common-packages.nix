{
  aspects.common-packages =
    {
      inputs,
      username,
      pkgs,
      ...
    }:
    {
      home-manager.users.${username} = {
        imports = [ inputs.spicetify-nix.homeManagerModules.default ];

        home.packages = with pkgs; [
          (discord.override { withVencord = true; })
          anki
          claude-code
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
            customColorScheme = builtins.fromJSON (builtins.readFile ../../local/themes/spicetify.json);
          };
      };
    };
}
