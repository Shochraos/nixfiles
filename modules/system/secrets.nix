{ inputs, ... }:
{
  den.aspects.secrets =
    { host, user, ... }:
    {
      nixos =
        { lib, ... }:
        {
          imports = [ inputs.sops-nix.nixosModules.sops ];

          sops = {
            defaultSopsFile = ../../secrets/secrets.yaml;

            age.sshKeyPaths = [ "/home/${user.name}/.ssh/${lib.toLower host.name}" ];

            secrets."user-password-hash".neededForUsers = true;
          };
        };

      provides.to-users.homeManager =
        { lib, pkgs, ... }:
        {
          home.packages = [
            pkgs.sops
            pkgs.ssh-to-age
          ];

          home.sessionVariables.SOPS_AGE_KEY_CMD = "ssh-to-age -private-key -i /home/${user.name}/.ssh/${lib.toLower host.name}";
        };
    };
}
