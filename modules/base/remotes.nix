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
            "astaroth/ip" = { };
            "git/url-rewrites".owner = user.name;
          };

          sops.templates."ssh-secret-hosts" = {
            owner = user.name;
            content = ''
              Host ${config.sops.placeholder."ssh/uni-git"}
                AddKeysToAgent yes
                IdentityFile ${gitKey}

              Host ${config.sops.placeholder."ssh/private-git"}
                AddKeysToAgent yes
                IdentityFile ${gitKey}
                Port 2222

              Host astaroth
                AddKeysToAgent yes
                ForwardAgent yes
                HostName ${config.sops.placeholder."astaroth/ip"}
                IdentityFile ${config.host.sshKey}
                User root
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
              osConfig.sops.templates."ssh-secret-hosts".path
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

              "*" = {
                AddKeysToAgent = "yes";
                IdentityFile = hostKey;
              };
            };
          };
        };
    };
}
