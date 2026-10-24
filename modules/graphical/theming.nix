{ inputs, config, ... }:
let
  inherit (config) assets;

  notoCjkStatic = _final: prev: {
    noto-fonts-cjk-sans = prev.noto-fonts-cjk-sans.override { static = true; };
  };
in
{
  den.aspects.theming = {
    nixos =
      { config, pkgs, ... }:
      {
        imports = [ inputs.stylix.nixosModules.stylix ];

        environment.systemPackages = with pkgs; [
          bibata-cursors
          papirus-icon-theme
        ];

        nixpkgs.overlays = [ notoCjkStatic ];

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
            gtk.enable = true;
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
            dark = "Papirus-Matugen-Dark";
            light = "Papirus-Matugen-Dark";
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
        papirusRecolorTemplate = pkgs.runCommand "papirus-recolor.sh" { } ''
          install -m644 ${assets.papirusRecolorTemplate} $out
          substituteInPlace $out \
            --replace-fail '@PAPIRUS_ICONS@' '${pkgs.papirus-icon-theme}/share/icons' \
            --replace-fail '@GTK_CACHE@' '${pkgs.gtk3}/bin/gtk-update-icon-cache'
        '';
      in
      {
        home.pointerCursor.enable = true;

        fonts.fontconfig.enable = true;

        home.packages = with pkgs; [
          adw-gtk3
          qtengine
          klassy
          kdePackages.qqc2-desktop-style
        ];

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

        dconf.settings."org/gnome/desktop/interface" = {
          gtk-theme = "adw-gtk3-dark";
          color-scheme = "prefer-dark";
          icon-theme = config.stylix.icons.dark;
          font-name = "${config.stylix.fonts.sansSerif.name} ${toString config.stylix.fonts.sizes.applications}";
          monospace-font-name = "${config.stylix.fonts.monospace.name} ${toString config.stylix.fonts.sizes.applications}";
          font-antialiasing = "grayscale";
        };

        xdg.configFile."gtk-3.0/gtk.css".text = ''
          @import url("dank-colors.css");
        '';
        xdg.configFile."gtk-4.0/gtk.css".text = ''
          @import url("dank-colors.css");
        '';

        qt.enable = true;

        home.sessionVariables.QT_QPA_PLATFORMTHEME = "qtengine";

        xdg.configFile."klassy/klassyrc".source = assets.klassyRc;

        xdg.configFile."qtengine/config.json".text = builtins.toJSON {
          theme = {
            colorScheme = "${config.xdg.dataHome}/color-schemes/DankMatugen.colors";
            iconTheme = config.stylix.icons.dark;
            style = "klassy";
            quickStyle = "org.kde.desktop";
            font = {
              family = config.stylix.fonts.sansSerif.name;
              size = config.stylix.fonts.sizes.applications;
            };
            fontFixed = {
              family = config.stylix.fonts.monospace.name;
              size = config.stylix.fonts.sizes.applications;
            };
          };
          misc = {
            singleClickActivate = false;
            menusHaveIcons = true;
            shortcutsForContextMenus = true;
          };
        };

        xdg.configFile."matugen/config.toml".source = (pkgs.formats.toml { }).generate "matugen-config" {
          config = { };
          templates = {
            spotifast = {
              input_path = assets.spotifastTemplate;
              output_path = "~/.config/spotifast/themes/matugen.json";
            };

            vesktop = {
              input_path = assets.discordTemplate;
              output_path = "~/.config/Equicord/themes/matugen.css";
            };

            starship = {
              input_path = assets.matugenStarshipTemplate;
              output_path = "~/.config/starship.toml";
            };

            papirus-folders = {
              input_path = papirusRecolorTemplate;
              output_path = "~/.cache/papirus-matugen/recolor.sh.tmp";
              post_hook = "mv ~/.cache/papirus-matugen/recolor.sh.tmp ~/.cache/papirus-matugen/recolor.sh";
            };

            btop = {
              input_path = assets.matugenBtopTemplate;
              output_path = "~/.config/btop/themes/matugen.theme";
              post_hook = "${pkgs.procps}/bin/pkill -USR2 -u \"$USER\" -x btop || true";
            };

            flyline = {
              input_path = assets.matugenFlylineTemplate;
              output_path = "~/.cache/flyline/matugen.sh";
            };
          }
          // osConfig.host.matugen.templates;
        };

        systemd.user.paths.papirus-matugen = {
          Unit.Description = "Run the Papirus icon recolor script whenever matugen renders it";
          Path.PathExists = "${config.xdg.cacheHome}/papirus-matugen/recolor.sh";
          Install.WantedBy = [ "graphical-session.target" ];
        };

        systemd.user.services.papirus-matugen = {
          Unit = {
            Description = "Rebuild Papirus-Matugen-Dark icons from the rendered matugen script";
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.bash}/bin/bash ${config.xdg.cacheHome}/papirus-matugen/recolor.sh";
            RuntimeMaxSec = "15min";
          };
        };
      };
  };
}
