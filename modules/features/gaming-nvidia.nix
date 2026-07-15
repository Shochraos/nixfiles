{
  den.aspects.gaming.nixos =
    {
      config,
      pkgs,
      ...
    }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      environment.systemPackages = with pkgs; [
        nvidia-vaapi-driver
        egl-wayland
      ];
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        powerManagement.finegrained = false;
        open = true;
        nvidiaSettings = false;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
    };

  den.aspects.gaming.provides.to-users.homeManager = {
    home.sessionVariables = {
      "LIBVA_DRIVER_NAME" = "nvidia";
      "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
      "NVD_BACKEND" = "direct";
      "__GL_SHADER_DISK_CACHE" = "1";
      "__GL_SHADER_DISK_CACHE_SIZE" = "51539607552"; # 48 GiB
    };
  };
}
