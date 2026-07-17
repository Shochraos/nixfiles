{
  den.aspects.virtualization =
    { user, ... }:
    {
      nixos = {
        programs.virt-manager.enable = true;

        users.groups.libvirtd.members = [ user.name ];

        virtualisation.libvirtd.enable = true;

        virtualisation.spiceUSBRedirection.enable = true;

        virtualisation.vswitch.enable = true;
      };
    };
}
