{
  aspects.home.remotes =
    {
      lib,
      username,
      systemname,
      ...
    }:
    {
      programs.git = {
        enable = true;
        settings = {
          user.name = "Shochraos";
          user.email = "github@shonline.slmail.me";
          core.excludesfile = "/home/${username}/.gitignore";
          init.defaultBranch = "main";
        };
        extraConfig = {
          url."git@git-ce.rwth-aachen.de:".insteadOf = "https://git-ce.rwth-aachen.de/";
        };
      };

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        settings = {
          "github.com" = {
            forwardAgent = true;
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}-git";
          };
          "codeberg.org" = {
            forwardAgent = true;
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}-git";
          };

          "private-cloud.informatik.hs-fulda.de" = {
            forwardAgent = true;
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/openstack-uni";
          };

          "git-ce.rwth-aachen.de" = {
            forwardAgent = true;
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}-git";
          };

          "git.freunds.me" = {
            forwardAgent = true;
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}-git";
            Port = "2222";
          };

          "astaroth" = {
            forwardAgent = true;
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}";
            HostName = "192.168.10.2";
            User = "root";
          };

          "*" = {
            forwardAgent = true;
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}";
          };
        };
      };
    };
}
