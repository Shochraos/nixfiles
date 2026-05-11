{
  pkgs,
  config,
  username,
  ...
}:
{
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

  environment.systemPackages = with pkgs; [ bibata-cursors ];

  services.displayManager.dms-greeter = {
    compositor.customConfig = ''
      env = XCURSOR_THEME,Bibata-Modern-Classic
      env = XCURSOR_SIZE,24

      misc:disable_hyprland_logo = true
      misc:disable_splash_rendering = true
      misc:force_default_wallpaper = 0
      misc:background_color = rgb(000000)
    '';
  };

  programs.dconf.enable = true;

  home-manager.users.${username} = {
    xdg.configFile."matugen/config.toml".source = ../../configs/matugen/config.toml;

    home.packages = with pkgs; [
      adw-gtk3
      overpass
      nerd-fonts.overpass
    ];

    programs.dank-material-shell.settings = {
      # Matugen
      currentThemeName = "dynamic";
      currentThemeCategory = "dynamic";
      matugenScheme = "scheme-fidelity";
      widgetBackgroundColor = "sth";
      widgetColorMode = "default";

      popupTransparency = 0.2;
      
      # Fonts
      fontFamily = config.stylix.fonts.sansSerif.name;
      monoFontFamily = config.stylix.fonts.monospace.name;
      fontScale = 1;
      fontWeight = 400;
    };

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
