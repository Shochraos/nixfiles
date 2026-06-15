{
  aspects.nixos.theme =
    {
      pkgs,
      config,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [ bibata-cursors ];

      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/chalk.yaml";
        autoEnable = false;

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

  aspects.home.theme =
    { pkgs, ... }:
    {
      xdg.configFile."matugen/config.toml".source = ../../configs/matugen/config.toml;

      home.packages = with pkgs; [
        adw-gtk3
        overpass
        nerd-fonts.overpass
      ];

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          gtk-theme = "adw-gtk3-dark";
          color-scheme = "prefer-dark";
        };
      };

      qt = {
        enable = true;
        platformTheme.name = "qtct";
      };

      stylix.targets.zed.fonts.enable = true;
      stylix.targets.gtk.fonts.enable = true;
    };
}
