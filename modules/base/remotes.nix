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
            "git/github/email" = { };
            "git/non-github/name" = { };
            "git/non-github/email" = { };
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

          sops.templates."git-github-identity" = {
            owner = user.name;
            content = ''
              [user]
              email = ${config.sops.placeholder."git/github/email"}
            '';
          };

          sops.templates."git-non-github-identity" = {
            owner = user.name;
            content = ''
              [user]
              name = ${config.sops.placeholder."git/non-github/name"}
              email = ${config.sops.placeholder."git/non-github/email"}
            '';
          };
        };

      provides.to-users.homeManager =
        { config, osConfig, ... }:
        let
          hostKey = osConfig.host.sshKey;
          gitKey = "${hostKey}-git";
          nonGithubHosts = [
            "codeberg.org"
            "git-ce.rwth-aachen.de"
          ];
          nonGithubIdentity = osConfig.sops.templates."git-non-github-identity".path;
          githubIdentity = osConfig.sops.templates."git-github-identity".path;
          nonGithubIncludes = builtins.concatMap (host: [
            {
              condition = "hasconfig:remote.*.url:https://${host}/**";
              path = nonGithubIdentity;
            }
            {
              condition = "hasconfig:remote.*.url:git@${host}:**/*";
              path = nonGithubIdentity;
            }
          ]) nonGithubHosts;
        in
        {
          programs.git = {
            enable = true;
            settings = {
              user.name = "Shochraos";
              core.excludesfile = "${config.home.homeDirectory}/.gitignore";
              init.defaultBranch = "main";
            };
            includes = [
              { path = githubIdentity; }
              { path = osConfig.sops.secrets."git/url-rewrites".path; }
            ]
            ++ nonGithubIncludes;
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
