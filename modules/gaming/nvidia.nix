{ config, ... }:
{
  hardware.graphics =
  {
    enable = true;
  };

  boot.kernelParams = [ "nvidia.NVreg_TemporaryFilePath=/var/tmp" ];
  
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia =
  {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
}
