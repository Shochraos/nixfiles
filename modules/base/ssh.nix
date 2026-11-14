{
  den.aspects.ssh = _: {
    nixos = {
      sops.secrets."ssh/hosts".owner = "shochraos";

      programs.ssh.knownHosts.astaroth = {
        hostNames = [ "astaroth" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMClDh2uo4ZSfbdVnvWagVd06gORzbyQrETNSNFtFmQ6";
      };
    };

    provides.to-users.homeManager =
      {
        config,
        lib,
        osConfig,
        ...
      }:
      {
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          includes = lib.optionals (config.home.username == "shochraos") [
            osConfig.sops.secrets."ssh/hosts".path
          ];

          settings = lib.mkIf (config.home.username == "shochraos") {
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
