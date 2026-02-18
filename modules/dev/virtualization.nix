{ username, ... }:
{
  programs.virt-manager.enable = true;
    
  users.groups.libvirtd.members = [username];
  
  virtualisation.libvirtd.enable = true;
  
  virtualisation.spiceUSBRedirection.enable = true;
}