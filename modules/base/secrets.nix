{ inputs, config, ... }:
let
  inherit (config) assets;
in
{
  den.aspects.secrets.nixos =
    { config, lib, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        defaultSopsFile = assets.sopsFile;

        age.sshKeyPaths = lib.mkDefault [ config.host.sshKey ];

        secrets."user-password-hash".neededForUsers = true;
      };
    };

}
