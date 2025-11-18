{ pkgs, lib, isAzazel, ... }:
{
  # Browser
  programs.zen-browser.enable = true;

  # Packages
  home.packages = with pkgs;
  [
    # GUI
    (discord.override { withVencord = true; })
    pdfslicer
    nextcloud-client

    # IDE with plugins
    jetbrains.pycharm-community
    jetbrains.clion

    # CLI
    nix-your-shell
    eza
    fd
    btop

    # Development
    devenv
  ]
  ++ lib.optionals isAzazel (with pkgs;
  [
    # GUI
    jellyfin-mpv-shim
    spotify

    # Wallets
    feather
    #electrum
    #electrum-ltc

    # Gaming
    samrewritten
    protonup-qt
  ]);
}