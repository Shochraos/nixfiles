{ inputs, pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;

  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.default ];
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4;
}
