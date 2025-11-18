{ pkgs, inputs, lib, isAzazel, ... }:
{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # SSH
  programs.ssh.startAgent = true;

  # Shell
  programs.fish.enable = true;

  # Preinstalled applications
  programs.firefox.enable = false;

  # Packages that require system access
  environment.systemPackages =
  with pkgs;
  []
  ++ lib.optionals isAzazel (with pkgs;
  [
    # Access to the lactd daemon
    lact
  ]);

  # Steam
  nixpkgs.overlays = lib.optionals isAzazel [ inputs.millennium.overlays.default ];
  programs.steam = lib.mkIf isAzazel
  {
    enable = true;
    package = pkgs.steam-millennium;
    remotePlay.openFirewall = true;
  };

  # LACT daemon
  systemd = lib.mkIf isAzazel
  {
    packages = with pkgs; [ lact ];
    services.lactd.wantedBy = [ "multi-user.target" ];
  };
}