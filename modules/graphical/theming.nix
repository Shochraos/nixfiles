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
          base16Scheme = {
            system = "base16";
            name = "Chalk";
            author = "Chris Kempson (http://chriskempson.com)";
            variant = "dark";
            palette = {
              base00 = "#151515";
              base01 = "#202020";
              base02 = "#303030";
              base03 = "#505050";
              base04 = "#b0b0b0";
              base05 = "#d0d0d0";
              base06 = "#e0e0e0";
              base07 = "#f5f5f5";
              base08 = "#fb9fb1";
              base09 = "#eda987";
              base0A = "#ddb26f";
              base0B = "#acc267";
              base0C = "#12cfc0";
              base0D = "#6fc2ef";
              base0E = "#e1a3ee";
              base0F = "#deaf8f";
            };
          };
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
        tutaMatugenEnabled = osConfig.networking.hostName == "Azazel";
        tutaMatugen = pkgs.writeShellApplication {
          name = "tutanota-matugen";
          excludeShellChecks = [
            "SC2089"
            "SC2090"
          ];
          runtimeInputs = with pkgs; [
            coreutils
            diffutils
            jq
            procps
            util-linux
          ];
          runtimeEnv = {
            TUTA_EXECUTABLE = "${pkgs.tutanota-desktop}/bin/tutanota-desktop";
            TUTA_THEME_KEYS = builtins.toJSON (
              builtins.attrNames (builtins.fromJSON (builtins.readFile assets.tutanotaTemplate))
            );
          };
          text = builtins.readFile assets.tutanotaMatugenScript;
        };
        tutaDesktop = pkgs.symlinkJoin {
          name = "tutanota-desktop-matugen-${pkgs.tutanota-desktop.version}";
          paths = [ pkgs.tutanota-desktop ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            rm "$out/bin/tutanota-desktop"
            makeWrapper ${tutaMatugen}/bin/tutanota-matugen "$out/bin/tutanota-desktop" \
              --add-flags --launch
          '';
          inherit (pkgs.tutanota-desktop) meta;
        };

        hermesDesktopTemplate = pkgs.writeText "hermes-desktop.js" (
          builtins.replaceStrings
            [
              "'@HERMES_FONT_SANS@'"
              "'@HERMES_FONT_MONO@'"
            ]
            [
              (builtins.toJSON "${builtins.toJSON config.stylix.fonts.sansSerif.name}, sans-serif")
              (builtins.toJSON "${builtins.toJSON config.stylix.fonts.monospace.name}, monospace")
            ]
            (builtins.readFile assets.hermesDesktopTemplate)
        );

        papirusRecolor = pkgs.writeShellApplication {
          name = "papirus-recolor";
          runtimeInputs = with pkgs; [
            coreutils
            findutils
            gnugrep
            gnused
            util-linux
          ];
          runtimeEnv = {
            PAPIRUS_ROOT = "${pkgs.papirus-icon-theme}/share/icons";
            GTK_CACHE = "${pkgs.gtk3}/bin/gtk-update-icon-cache";
            PAPIRUS_CACHE = "${config.xdg.cacheHome}/papirus-matugen";
            PAPIRUS_OUTPUT = "${config.xdg.dataHome}/icons";
          };
          text = builtins.readFile assets.papirusRecolorScript;
        };
      in
      {
        home.pointerCursor.enable = true;

        fonts.fontconfig.enable = true;

        home.packages =
          (with pkgs; [
            adw-gtk3
            qtengine
            klassy
            kdePackages.qqc2-desktop-style
          ])
          ++ pkgs.lib.optional tutaMatugenEnabled tutaDesktop;

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

        dconf.settings."org/gtk/Settings/FileChooser".window-size =
          inputs.home-manager.lib.hm.gvariant.mkTuple
            [
              1200
              900
            ];

        xdg.configFile."gtk-3.0/gtk.css".text = ''
          @import url("dank-colors.css");
        '';
        xdg.configFile."gtk-4.0/gtk.css".text = ''
          @import url("dank-colors.css");
        '';

        qt.enable = true;

        home.sessionVariables.QT_QPA_PLATFORMTHEME = "qtengine";

        xdg.configFile."klassy/klassyrc".source = assets.klassyRc;

        xdg.configFile."qtengine/config.json" = {
          force = true;
          text = builtins.toJSON {
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
        };

        xdg.configFile."matugen/config.toml".source =
          let
            dropUnsetHooks = pkgs.lib.filterAttrs (_: value: value != null);
          in
          (pkgs.formats.toml { }).generate "matugen-config" {
            config = { };
            templates = pkgs.lib.mapAttrs (_: dropUnsetHooks) (
              {
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

                hyprtoolkit = {
                  input_path = pkgs.writeText "hyprtoolkit.conf" ''
                    background = 0xff{{colors.surface.default.hex_stripped}}
                    base = 0xff{{colors.surface_container.default.hex_stripped}}
                    text = 0xff{{colors.on_surface.default.hex_stripped}}
                    alternate_base = 0xff{{colors.surface_container_highest.default.hex_stripped}}
                    bright_text = 0xff{{colors.on_primary.default.hex_stripped}}
                    link_text = 0xff{{colors.primary.default.hex_stripped}}
                    accent = 0xff{{colors.primary.default.hex_stripped}}
                    accent_secondary = 0xff{{colors.secondary.default.hex_stripped}}
                    rounding_large = 14
                    rounding_small = 7
                  '';
                  output_path = "~/.config/hypr/hyprtoolkit.conf";
                };

                hermes-desktop = {
                  input_path = hermesDesktopTemplate;
                  output_path = "~/.hermes/desktop-plugins/matugen/plugin.js.tmp";
                  post_hook = "${pkgs.coreutils}/bin/mv -f -- \"$HOME/.hermes/desktop-plugins/matugen/plugin.js.tmp\" \"$HOME/.hermes/desktop-plugins/matugen/plugin.js\"";
                };

                papirus-folders = {
                  input_path = assets.papirusPaletteTemplate;
                  output_path = "${config.xdg.cacheHome}/papirus-matugen/palette.txt.tmp";
                  post_hook = "${papirusRecolor}/bin/papirus-recolor --publish";
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
              // pkgs.lib.optionalAttrs tutaMatugenEnabled {
                tutanota = {
                  input_path = assets.tutanotaTemplate;
                  output_path = "${config.xdg.cacheHome}/tutanota-matugen/theme.json.tmp";
                  post_hook = "${tutaMatugen}/bin/tutanota-matugen --publish";
                };
              }
              // osConfig.host.matugen.templates
            );
          };

        systemd.user.paths.papirus-matugen = {
          Unit = {
            Description = "Rebuild Papirus icons whenever matugen publishes a palette";
            PartOf = [ "graphical-session.target" ];
          };
          Path.PathExists = "${config.xdg.cacheHome}/papirus-matugen/pending";
          Install.WantedBy = [ "graphical-session.target" ];
        };

        systemd.user.services.papirus-matugen = {
          Unit = {
            Description = "Reconcile Papirus-Matugen-Dark icons with the current generation";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Install.WantedBy = [ "graphical-session.target" ];
          Service = {
            Type = "oneshot";
            Restart = "on-failure";
            RestartSec = "30s";
            ExecStart = "${papirusRecolor}/bin/papirus-recolor";
            TimeoutStartSec = "15min";
          };
        };
      };
  };
}
