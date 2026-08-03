{
  den.aspects.shochraos =
    { user, ... }:
    {
      nixos =
        { config, ... }:
        {
          users.mutableUsers = false;

          users.users.${user.name} = {
            isNormalUser = true;
            hashedPasswordFile = config.sops.secrets."user-password-hash".path;
            extraGroups = [
              "wheel"
              "networkmanager"
            ];
          };

          users.users.root.hashedPasswordFile = config.sops.secrets."user-password-hash".path;
        };

    };
}
