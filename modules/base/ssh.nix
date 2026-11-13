{
  den.aspects.ssh =
    { user, ... }:
    {
      nixos = {
        sops.secrets."ssh/hosts".owner = user.name;

        programs.ssh.knownHosts.astaroth = {
          hostNames = [ "astaroth" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMClDh2uo4ZSfbdVnvWagVd06gORzbyQrETNSNFtFmQ6";
        };
      };

      provides.to-users.homeManager =
        { osConfig, ... }:
        {
          programs.ssh = {
            enable = true;
            enableDefaultConfig = false;
            includes = [ osConfig.sops.secrets."ssh/hosts".path ];

            settings = {
              astaroth = {
                AddKeysToAgent = "yes";
                ForwardAgent = "yes";
                HostName = "192.168.10.2";
                IdentityFile = osConfig.host.sshKey;
                User = "root";
                HostKeyAlias = "astaroth";
                StrictHostKeyChecking = "yes";
              };
              "*" = {
                AddKeysToAgent = "yes";
                IdentityFile = osConfig.host.sshKey;
              };
            };
          };
        };
    };
}
