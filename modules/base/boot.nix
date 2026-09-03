{ inputs, ... }:
{
  den.aspects.boot.nixos =
    { lib, pkgs, ... }:
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      boot.loader.systemd-boot.enable = lib.mkForce false;

      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        configurationLimit = 10;
      };

      boot.loader.efi.canTouchEfiVariables = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;
    };
}
