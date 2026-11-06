{ den, ... }:
{
  den.aspects.nvidia.includes = [ (den.batteries.unfree [ "nvidia-x11" ]) ];

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
          version = "620.70.06";
          sha256_64bit = "sha256-KRGOOr0IwHVZvMo9nHYjjQOUkK8DYqLlvPy+cgSv1LE=";
          sha256_aarch64 = "sha256-P6ZaknHg3eKk5YxJZcOIhaAqOkKszcsm/IF0EGB/PgM=";
          openSha256 = "sha256-dV8vzniUl3UJoG2Q3KdoUJigLRuQeTniUfB670gb1Mw=";
          settingsSha256 = "sha256-CFBRmXFJ9eAf5BRlHMBolahz1Pshr9giI7zcZC29oZ8=";
          persistencedSha256 = "sha256-FpGzhArrvR1nEt8lKDzNEnbvHvGP36gL1dINvpDAkpA=";
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
