{ inputs, ... }:
{
  aspects.nixos.secrets =
    {
      lib,
      username,
      systemname,
      ...
    }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        defaultSopsFile = ../../secrets/secrets.yaml;

        age.sshKeyPaths = [ "/home/${username}/.ssh/${lib.toLower systemname}" ];

        secrets."user-password-hash".neededForUsers = true;
      };
    };

  aspects.home.secrets =
    {
      lib,
      pkgs,
      username,
      systemname,
      ...
    }:
    {
      home.packages = [
        pkgs.sops
        pkgs.ssh-to-age
      ];

      home.sessionVariables.SOPS_AGE_KEY_CMD =
        "ssh-to-age -private-key -i /home/${username}/.ssh/${lib.toLower systemname}";
    };
}
