{
  aspects.nixos.azazel = {
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=4G"
        "mode=755"
      ];
    };

    fileSystems."/persist" = {
      device = "/dev/disk/by-uuid/4c651ae6-5cff-446f-a8f0-323a9f047f90";
      fsType = "ext4";
      neededForBoot = true;
    };

    fileSystems."/nix" = {
      device = "/persist/nix";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/C48B-9EE7";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    fileSystems."/mnt/games" = {
      device = "/dev/disk/by-uuid/f2810853-5fce-4598-9790-305dda5b13c0";
      fsType = "btrfs";
    };

    swapDevices = [
      {
        device = "/dev/disk/by-uuid/b59488dd-4453-432c-b2c9-712796ee9ad5";
      }
      {
        device = "/persist/var/lib/swapfile";
        size = 32 * 1024;
      }
    ];
  };
}
