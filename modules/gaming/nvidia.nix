{ inputs, config, ... }:
{
  hardware.graphics =
  {
    enable = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia =
  {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = false;
    #package = config.boot.kernelPackages.nvidiaPackages.stable;
    package =
          let
            nvidia-fixed-pkgs = import inputs.nixpkgs-nvidia {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
            fixedKernelPackages = nvidia-fixed-pkgs.linuxKernel.packagesFor config.boot.kernelPackages.kernel;
          in
          fixedKernelPackages.nvidiaPackages.beta;
  };
}
