{ lib, username, systemname, ... }:
{
  home-manager.users.${username} =
  {
    programs.ssh = 
    {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks."github.com" =
      {
        forwardAgent = true;
        extraOptions = 
        {
          AddKeysToAgent = "yes";
          IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}-git";
        };
      };

      matchBlocks."git.freunds.me" =
      {
        forwardAgent = true;
        extraOptions = 
        {
          AddKeysToAgent = "yes";
          IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}-git";
          Port = "2222";
        };
      };

      matchBlocks."astaroth" =
      {
        forwardAgent = true;
        extraOptions = 
        {
          AddKeysToAgent = "yes";
          IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}";
          HostName = "192.168.10.2";
          User = "root";
        };
      };

      matchBlocks."*" =
      {
        forwardAgent = true;
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}";
        };
      };
    };
  };
}
