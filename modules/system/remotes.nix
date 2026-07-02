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
          url."git@git-ce.rwth-aachen.de:".insteadOf = "https://git-ce.rwth-aachen.de/";
        };
      };

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        settings = {
          "github.com" = {
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}-git";
          };
          "codeberg.org" = {
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}-git";
          };

          "private-cloud.informatik.hs-fulda.de" = {
            forwardAgent = true;
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/openstack-uni";
          };

          "git-ce.rwth-aachen.de" = {
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}-git";
          };

          "git.freunds.me" = {
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
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}";
          };
        };
      };
    };
}
