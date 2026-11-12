{ inputs, ... }:
let
  systemDisk = "/dev/disk/by-id/REPLACE_WITH_SITRI_WHOLE_DISK";
  swapDisk = "/dev/disk/by-id/REPLACE_WITH_SITRI_EMMC_WHOLE_DISK";
in
{
  den.aspects.sitri.nixos = {
    imports = [ inputs.disko.nixosModules.disko ];

    disko.devices.disk.system.device = systemDisk;

    disko.devices.disk.system = {
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              extraFormatArgs = [
                "--type"
                "luks2"
              ];
              settings.crypttabExtraOpts = [ "tpm2-device=auto" ];
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };

    disko.devices.disk.swap = {
      type = "disk";
      device = swapDisk;
      content = {
        type = "gpt";
        partitions.swap = {
          size = "100%";
          type = "8200";
          device = "${swapDisk}-part1";
          content = {
            type = "swap";
            randomEncryption = true;
            priority = 0;
          };
        };
      };
    };
  };
}
