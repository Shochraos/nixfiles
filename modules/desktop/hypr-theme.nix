{ inputs, ... }:
{
  den.aspects.hyprland =
    { host, ... }:
    {
      nixos =
        {
          pkgs,
          config,
          ...
        }:
        {
          imports = [ inputs.stylix.nixosModules.stylix ];

          environment.systemPackages = with pkgs; [
            bibata-cursors
            papirus-icon-theme
          ];

          stylix = {
            enable = true;
            base16Scheme = "${pkgs.base16-schemes}/share/themes/chalk.yaml";
            autoEnable = false;

            targets = {
              font-packages.enable = true;
              fontconfig.enable = true;
            };

            cursor = {
              package = pkgs.bibata-cursors;
              name = "Bibata-Modern-Classic";
              size = 24;
            };

            fonts = {
              packages = with pkgs; [
                noto-fonts-cjk-sans
                noto-fonts-cjk-serif
              ];

              serif = config.stylix.fonts.sansSerif;

              sansSerif = {
                package = pkgs.overpass;
                name = "Overpass";
              };

              monospace = {
                package = pkgs.nerd-fonts.overpass;
                name = "OverpassM Nerd Font Mono";
              };

              emoji = {
                package = pkgs.noto-fonts-color-emoji;
                name = "Noto Color Emoji";
              };
            };

            icons = {
              enable = true;
              package = pkgs.papirus-icon-theme;
              dark = "Papirus-Dark";
              light = "Papirus-Light";
            };
          };
          programs.dconf.enable = true;
        };

      provides.to-users.homeManager =
        { config, pkgs, ... }:
        {
          home.pointerCursor.enable = true;

          xdg.configFile."matugen/config.toml".text = ''
            [config]
            [templates.spotify]
            input_path = '~/Repositories/nixfiles/assets/templates/spicetify.json.j2'
            output_path = '~/Repositories/nixfiles/configs/matugen/spicetify-${host.name}.json'

            [templates.vesktop]
            input_path = '~/Repositories/nixfiles/assets/templates/discord.css'
            output_path = '~/.config/Vencord/themes/matugen.css'

            [templates.steam]
            input_path = '~/Repositories/nixfiles/assets/templates/steam.css'
            output_path = '~/.steam/steam/millennium/themes/simply-dark/colors.css'
          '';

          home.packages = with pkgs; [ adw-gtk3 ];

          fonts.fontconfig.enable = true;

          dconf.settings = {
            "org/gnome/desktop/interface" = {
              gtk-theme = "adw-gtk3-dark";
              color-scheme = "prefer-dark";
              icon-theme = config.stylix.icons.dark;
              font-name = "${config.stylix.fonts.sansSerif.name} ${toString config.stylix.fonts.sizes.applications}";
              monospace-font-name = "${config.stylix.fonts.monospace.name} ${toString config.stylix.fonts.sizes.applications}";
            };
          };

          qt = {
            enable = true;
            platformTheme.name = "qtct";
          };

          stylix.targets = {
            font-packages.enable = true;
            fontconfig.enable = true;
            gtk = {
              enable = true;
              colors.enable = false;
            };
            zed = {
              enable = true;
              colors.enable = false;
            };
          };
        };
    };
}
