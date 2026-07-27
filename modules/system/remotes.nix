{
  den.aspects.remotes =
    { user, ... }:
    {
      nixos =
        { config, ... }:
        let
          gitKey = "${config.host.sshKey}-git";
        in
        {
          sops.secrets = {
            "ssh/hosts".owner = user.name;
            "ssh/private-git" = { };
            "ssh/uni-git" = { };
            "git/url-rewrites".owner = user.name;
          };

          sops.templates."ssh-git-hosts" = {
            owner = user.name;
            content = ''
              Host ${config.sops.placeholder."ssh/uni-git"}
                AddKeysToAgent yes
                IdentityFile ${gitKey}

              Host ${config.sops.placeholder."ssh/private-git"}
                AddKeysToAgent yes
                IdentityFile ${gitKey}
                Port 2222
            '';
          };
        };

      provides.to-users.homeManager =
        { config, osConfig, ... }:
        let
          hostKey = osConfig.host.sshKey;
          gitKey = "${hostKey}-git";
        in
        {
          programs.git = {
            enable = true;
            settings = {
              user.name = "Shochraos";
              user.email = "github@shonline.slmail.me";
              core.excludesfile = "${config.home.homeDirectory}/.gitignore";
              init.defaultBranch = "main";
            };
            includes = [
              { path = osConfig.sops.secrets."git/url-rewrites".path; }
            ];
          };

          programs.ssh = {
            enable = true;
            enableDefaultConfig = false;

            includes = [
              osConfig.sops.secrets."ssh/hosts".path
              osConfig.sops.templates."ssh-git-hosts".path
            ];

            settings = {
              "github.com" = {
                AddKeysToAgent = "yes";
                IdentityFile = gitKey;
              };
              "codeberg.org" = {
                AddKeysToAgent = "yes";
                IdentityFile = gitKey;
              };

              "astaroth" = {
                forwardAgent = true;
                AddKeysToAgent = "yes";
                IdentityFile = hostKey;
                HostName = "192.168.10.2";
                User = "root";
              };

              "*" = {
                AddKeysToAgent = "yes";
                IdentityFile = hostKey;
              };
            };
          };
        };
    };
}
