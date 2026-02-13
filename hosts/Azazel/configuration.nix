{ ... }: 
{
  imports = 
  [  
    ../../modules/core
    ../../modules/nix
    
    ../../modules/gaming
    
    ../../modules/utilities/amdpower.nix
  ];

  networking.hostName = "azazel";
}