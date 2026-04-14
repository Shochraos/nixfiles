{ ... }: 
{
  imports = 
  [  
    ../../modules/core
    ../../modules/nix
    ../../modules/desktop
    
    ../../modules/gaming
    ../../modules/dev
    
    ../../modules/addons/bluetooth.nix
    ../../modules/addons/cloud.nix
    ../../modules/addons/common-packages.nix
    ../../modules/addons/mpv.nix
    ../../modules/addons/sshfs.nix
    ../../modules/addons/office.nix
    ../../modules/addons/scanprint.nix
    ../../modules/addons/kde-connect.nix
    ../../modules/addons/scx.nix
    
    ../../modules/utilities/amdpower.nix
    ../../modules/utilities/gamechat.nix
    ../../modules/utilities/inputremapper.nix
    ../../modules/utilities/lgtv.nix
    ../../modules/utilities/mp3tag.nix
    ../../modules/utilities/preventsleep.nix
  ];
}