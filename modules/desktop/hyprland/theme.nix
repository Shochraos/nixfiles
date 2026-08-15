{ inputs, config, ... }:
let
  inherit (config) assets;
in
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

          fonts.packages = with pkgs; [
            noto-fonts-cjk-sans
            noto-fonts-cjk-serif
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
        {
          config,
          osConfig,
          pkgs,
          ...
        }:
        let
          themeSync = pkgs.writeShellApplication {
            name = "theme-sync";
            runtimeInputs = with pkgs; [
              coreutils
              diffutils
              git
              jq
            ];
            text = ''
              src="$HOME/.local/state/matugen/spicetify-${host.name}.json"
              dst="${osConfig.host.flakeDir}/configs/matugen/spicetify-${host.name}.json"

              if [ ! -f "$src" ]; then exit 0; fi

              if ! jq -e 'type=="object" and length>0 and all(.[]; test("^[0-9a-fA-F]{6}$"))' "$src" >/dev/null 2>&1; then
                echo "theme-sync: $src incomplete or malformed, keeping current theme" >&2
                exit 0
              fi

              if cmp -s "$src" "$dst"; then exit 0; fi

              new=0
              [ -e "$dst" ] || new=1
              mkdir -p "$(dirname "$dst")"
              cp "$src" "$dst"
              [ "$new" = 0 ] || git -C "${osConfig.host.flakeDir}" add --intent-to-add -- "$dst"
              echo "theme-sync: updated $dst"
            '';
          };
        in
        {
          home.pointerCursor.enable = true;

          xdg.configFile."matugen/config.toml".source = (pkgs.formats.toml { }).generate "matugen-config" {
            config = { };
            templates = {
              spotify = {
                input_path = assets.spicetifyTemplate;
                output_path = "~/.local/state/matugen/spicetify-${host.name}.json";
              };

              vesktop = {
                input_path = assets.discordTemplate;
                output_path = "~/.config/Vencord/themes/matugen.css";
              };

              steam = {
                input_path = assets.steamTemplate;
                output_path = "~/.steam/steam/millennium/themes/simply-dark/colors.css";
              };
            }
            // osConfig.host.matugen.templates;
          };

          home.packages = [
            pkgs.adw-gtk3
            themeSync
          ];

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
