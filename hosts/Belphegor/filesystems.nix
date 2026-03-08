{ ... }:
{
  fileSystems."/" =
      { device = "/dev/disk/by-uuid/696cd767-1897-43ec-b550-482f755ab1af";
        fsType = "ext4";
      };
  
    fileSystems."/boot" =
      { device = "/dev/disk/by-uuid/0EF3-6496";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };
  
    swapDevices = [ ];
}