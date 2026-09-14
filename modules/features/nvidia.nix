{
  den.aspects.nvidia.nixos =
    {
      config,
      pkgs,
      ...
    }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [ pkgs.libglvnd ];
        extraPackages32 = [ pkgs.pkgsi686Linux.libglvnd ];
      };

      environment.sessionVariables.LD_LIBRARY_PATH = [
        "/run/opengl-driver/lib"
        "/run/opengl-driver-32/lib"
      ];

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
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "615.71.09";
          sha256_64bit = "sha256-zc7tIrvrYSSNGm3qvCWWZz46ZQFpjucayNL9wo87cP4=";
          sha256_aarch64 = "sha256-IbekQhE7cFfmnPZaLY9NDYcF7CoNZ+2Qb7sRd4EOgWM=";
          openSha256 = "sha256-3gByMYIwFzRaLdDG+roCEOuKRRJDrljG9AlLnRZTirM=";
          settingsSha256 = "sha256-LK1LU8mDkM/XVRKPBtuOZh9nIP/lGFLAJnmasEX8jhg=";
          persistencedSha256 = "sha256-qPRb+3d88+2RcpUkoBTbjIaImnQ+jX+/6p1vXcJ5geE=";
        };
      };
    };

  den.aspects.nvidia.provides.to-users.homeManager = {
    home.sessionVariables = {
      "LIBVA_DRIVER_NAME" = "nvidia";
      "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
      "NVD_BACKEND" = "direct";
      "__GL_SHADER_DISK_CACHE" = "1";
      "__GL_SHADER_DISK_CACHE_SIZE" = "51539607552"; # 48 GiB
    };
  };
}
