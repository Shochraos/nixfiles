{ pkgs, lib, systemName, ... }:
{
  # Browser
  programs.zen-browser.enable = true;

  # Packages
  home.packages = with pkgs;
  [
    # GUI
    (discord.override { withVencord = true; })
    pdfslicer

    # IDE with plugins
    (jetbrains.plugins.addPlugins jetbrains.idea-ultimate ["github-copilot" "nixidea"])

    # CLI
    nix-your-shell
    btop
  ]
  ++ lib.optionals (systemName == "Azazel") (with pkgs;
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
    r2modman
  ]);
}