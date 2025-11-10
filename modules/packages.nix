{ config, pkgs, inputs, ... }: {

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # SSH
  programs.ssh.startAgent = true;

  # Shell
  programs.fish.enable = true;

  # Steam
  nixpkgs.overlays = [ inputs.millennium.overlays.default ];
  programs.steam = {
    enable = true;
    package = pkgs.steam-millennium;
  };

  # Additional packages not managed by home-manager
  environment.systemPackages = with pkgs; [
    # GUI
    (discord.override {
    withVencord = true;
    })
    jetbrains.idea-ultimate
    spotify
    pdfslicer
    jellyfin-mpv-shim

    # Wallets
    feather
    #electrum
    #electrum-ltc

    # CLI
    nix-your-shell
    btop

    # Deps
    pulseaudio
    #nodejs

    # Gaming
    lact
    samrewritten
    protonup-qt
    r2modman
  ];

   # LACT daemon
  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = ["multi-user.target"];

  # Default applications
  programs.firefox.enable = false;
}
