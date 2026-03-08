{ ... }: 
{
  imports = 
  [  
    ../../modules/core
    ../../modules/nix
    
    ../../modules/dev
    
    ../../modules/addons/bluetooth.nix
    ../../modules/addons/common-packages.nix
    ../../modules/addons/office.nix
    ../../modules/addons/scanprint.nix
  ];
}