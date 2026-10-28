{ inputs, ... }:
{
  den.aspects.boot.nixos =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        sbctl
      ];

      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      boot.loader.systemd-boot.enable = lib.mkForce false;

      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        configurationLimit = 4;
        settings = {
          console-mode = "max";
          auto-firmware = false;
          auto-reboot = false;
          auto-poweroff = false;
          editor = false;
          timeout = "menu-hidden";
        };

        autoGenerateKeys.enable = false;
        autoEnrollKeys = {
          enable = false;
          autoReboot = false;
          includeMicrosoftKeys = true;
          includeChecksumsFromTPM = false;
        };
      };

      boot.loader.efi.canTouchEfiVariables = false;

      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.kernelParams = [ "nvme_core.default_ps_max_latency_us=0" ];
    };
}
