{ config, username, pkgs, ... }:
{
  hardware.graphics =
  {
    enable = true;
  };
  
  environment.systemPackages = with pkgs; [ nvidia-vaapi-driver egl-wayland ];
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
  
  home-manager.users.${username} = 
  {
    home.sessionVariables = 
    {
      "LIBVA_DRIVER_NAME" = "nvidia";
      "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
      "NVD_BACKEND" = "direct";
    };
  };
}
