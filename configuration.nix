{ config, pkgs, lib, isAzazel, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.download-buffer-size = 524288000;
  imports =
  [
    # Hardware configuration
    ./hosts/hardware-configuration.nix

    # Modules
    ./modules/boot.nix
    ./modules/desktop-environment.nix
    ./modules/bluetooth.nix
    ./modules/audio.nix
    ./modules/networking.nix
    ./modules/locale.nix
    ./modules/packages.nix
    ./modules/user.nix
    ./modules/automation.nix
  ]
  ++ lib.optionals isAzazel
  ([
    ./modules/graphics.nix
    ./modules/samba.nix
  ]);

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
