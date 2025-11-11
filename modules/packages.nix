{ config, pkgs, inputs, lib, ... }:
let
  Azazel = lib.mkIf (config.networking.hostName == "Azazel");
in
{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # SSH
  programs.ssh.startAgent = true;

  # Shell
  programs.fish.enable = true;

  # Default applications
  programs.firefox.enable = false;

  # Additional packages not managed by home-manager
  environment.systemPackages =
  with pkgs;
  [
    # GUI
    (discord.override { withVencord = true; })
    pdfslicer

    # IDE with plugins
    (jetbrains.plugins.addPlugins jetbrains.idea-ultimate ["github-copilot" "nixidea"])

    # CLI
    nix-your-shell
    btop

    # Deps
    pulseaudio
  ]
  ++ lib.optionals (config.networking.hostName == "Azazel") (with pkgs;
  [
    # GUI
    jellyfin-mpv-shim
    spotify

    # Wallets
    feather
    #electrum
    #electrum-ltc

    # Gaming
    lact
    samrewritten
    protonup-qt
    r2modman
  ]);

  # Steam
  nixpkgs.overlays = Azazel [ inputs.millennium.overlays.default ];
  programs.steam = Azazel {
    enable = true;
    package = pkgs.steam-millennium;
  };

  # LACT daemon
  systemd = Azazel {
    packages = with pkgs; [ lact ];
    services.lactd.wantedBy = [ "multi-user.target" ];
  };
}