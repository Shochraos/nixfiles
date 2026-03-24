{ username, ... }:
{
  services =
  {
    printing.enable = true;
    avahi =
    {
      enable = true;
      nssmdns4 = true;
    };
  };
  
  hardware.sane.enable = true;
  
  users.groups.lp.members = [ username ];
  users.groups.scanner.members = [ username ];
  
  environment.systemPackages = with pkgs; 
  [ 
    simple-scan
  ];
}