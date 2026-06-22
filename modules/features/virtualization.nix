{
  aspects.nixos.virtualization =
    { username, ... }:
    {
      programs.virt-manager.enable = true;

      users.groups.libvirtd.members = [ username ];

      virtualisation.libvirtd.enable = true;

      virtualisation.spiceUSBRedirection.enable = true;

      virtualisation.vswitch.enable = true;

      users.groups.frrvty = { };
      users.users.root.extraGroups = [ "frrvty" ];
    };
}
