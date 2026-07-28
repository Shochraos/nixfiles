{
  den.aspects.shochraos =
    { user, ... }:
    {
      nixos =
        { pkgs, config, ... }:
        {
          users.mutableUsers = false;

          users.users.${user.name} = {
            isNormalUser = true;
            shell = pkgs.fish;
            hashedPasswordFile = config.sops.secrets."user-password-hash".path;
            extraGroups = [
              "wheel"
              "networkmanager"
            ];
          };

          users.users.root.hashedPasswordFile = config.sops.secrets."user-password-hash".path;

          programs.fish.enable = true;
        };

    };
}
