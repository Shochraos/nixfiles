{ pkgs, lib, systemName, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks."github.com" =
    {
        forwardAgent = true;
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentityFile = "~/.ssh/${lib.toLower systemName}-git";
          };
    };

    matchBlocks."astaroth" =
    {
        forwardAgent = true;
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentityFile = "~/.ssh/${lib.toLower systemName}";
          HostName = "192.168.178.2";
          User = "root";
        };
    };

    matchBlocks."*" =
    {
      forwardAgent = true;
      extraOptions = {
        AddKeysToAgent = "yes";
        IdentityFile = "~/.ssh/${lib.toLower systemName}";
      };
    };
  };

  services.ssh-agent.enable = true;

  home.activation.add-ssh-key = ''
    ${pkgs.openssh}/bin/ssh-add ~/.ssh/${lib.toLower systemName} </dev/null || true
    ${pkgs.openssh}/bin/ssh-add ~/.ssh/${lib.toLower systemName}-git </dev/null || true
  '';
}

