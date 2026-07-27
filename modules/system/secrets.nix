{ inputs, ... }:
{
  den.aspects.secrets.nixos =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        defaultSopsFile = ../../secrets/secrets.yaml;

        age.sshKeyPaths = [ config.host.sshKey ];

        secrets."user-password-hash".neededForUsers = true;
      };
    };

  den.aspects.secrets.provides.to-users.homeManager =
    { osConfig, pkgs, ... }:
    {
      home.packages = [
        pkgs.sops
        pkgs.ssh-to-age
      ];

      home.sessionVariables.SOPS_AGE_KEY_CMD = "ssh-to-age -private-key -i ${osConfig.host.sshKey}";
    };
}
