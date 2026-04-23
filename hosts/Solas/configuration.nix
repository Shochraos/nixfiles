{ ... }:
{
  imports = [
    ../../modules/core
    ../../modules/nix
    ../../modules/desktop

    ../../modules/dev/virtualization.nix  

    ../../modules/addons/bluetooth.nix
    ../../modules/addons/fprint.nix
    ../../modules/addons/cloud.nix
    ../../modules/addons/common-packages.nix
    ../../modules/addons/office.nix
    ../../modules/addons/scanprint.nix
    ../../modules/addons/kde-connect.nix

    ../../modules/utilities/amdpower.nix
    ../../modules/utilities/mic-mute.nix
  ];
}
