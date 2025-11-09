{ pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks."github.com" = {
        forwardAgent = true;
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentityFile = "~/.ssh/azazel-git";
          };
    };

    matchBlocks."astaroth" = {
        forwardAgent = true;
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentityFile = "~/.ssh/azazel";
          HostName = "192.168.178.2";
          User = "root";
        };
    };

    matchBlocks."*" = {
      forwardAgent = true;
      extraOptions = {
        AddKeysToAgent = "yes";
        IdentityFile = "~/.ssh/azazel";
      };
    };
  };

  services.ssh-agent.enable = true;

  home.activation.add-ssh-key = ''
    ${pkgs.openssh}/bin/ssh-add ~/.ssh/azazel </dev/null || true
    ${pkgs.openssh}/bin/ssh-add ~/.ssh/azazel-git </dev/null || true
  '';
}

