{ config, pkgs, inputs, lib, systemName, ... }:
let
  Azazel = lib.mkIf (systemName == "Azazel");
in
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
  ++ lib.optionals (systemName == "Azazel") (with pkgs;
  [
    # Access to the lactd daemon
    lact
  ]);

  # Steam
  nixpkgs.overlays = Azazel [ inputs.millennium.overlays.default ];
  programs.steam = Azazel
  {
    enable = true;
    package = pkgs.steam-millennium;
  };

  # LACT daemon
  systemd = Azazel
  {
    packages = with pkgs; [ lact ];
    services.lactd.wantedBy = [ "multi-user.target" ];
  };
}