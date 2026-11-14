{
  den.aspects.shochraos =
    { user, ... }:
    {
      nixos =
        { config, ... }:
        {
          users.mutableUsers = false;
          services.openssh.settings.AllowUsers = [ user.name ];

          users.users.${user.name} = {
            isNormalUser = true;
            hashedPasswordFile = config.sops.secrets."user-password-hash".path;
            extraGroups = [
              "wheel"
              "networkmanager"
            ];
          };
        };

      homeManager =
        { osConfig, ... }:
        {
          home.sessionVariables.SOPS_AGE_KEY_CMD = "ssh-to-age -private-key -i ${osConfig.host.sshKey}";
        };

    };
}
