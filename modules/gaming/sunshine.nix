{ pkgs, ... }:
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  environment.systemPackages = [
      (pkgs.callPackage ../packages/moondeck-buddy { })
  ];
}