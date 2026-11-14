{
  den.aspects.virtualization =
    { ... }:
    {
      nixos = {
        programs.virt-manager.enable = true;

        users.groups.libvirtd.members = [ "shochraos" ];

        virtualisation.libvirtd.enable = true;

        virtualisation.spiceUSBRedirection.enable = true;
      };
    };
}
