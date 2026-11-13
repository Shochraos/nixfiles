{
  den.aspects.git =
    { user, ... }:
    {
      nixos =
        { config, ... }:
        let
          gitKey = "${config.host.sshKey}-git";
        in
        {
          sops.secrets = {
            "ssh/private-git" = { };
            "ssh/uni-git" = { };
            "git/url-rewrites".owner = user.name;
            "git/github/email" = { };
            "git/non-github/name" = { };
            "git/non-github/email" = { };
            "git/private-git" = { };
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

          sops.templates."git-identity-includes" =
            let
              includeIfBlock = condition: path: ''
                [includeIf "${condition}"]
                  path = ${path}
              '';
              hostBlocks =
                path: host:
                builtins.concatStringsSep "" (
                  map (condition: includeIfBlock condition path) [
                    "hasconfig:remote.*.url:https://${host}*/**"
                    "hasconfig:remote.*.url:git@${host}:**/*"
                    "hasconfig:remote.*.url:ssh://git@${host}*/**"
                  ]
                );
              nonGithubIdentity = config.sops.templates."git-non-github-identity".path;
              githubIdentity = config.sops.templates."git-github-identity".path;
            in
            {
              owner = user.name;
              content =
                hostBlocks nonGithubIdentity "codeberg.org"
                + hostBlocks nonGithubIdentity "git-ce.rwth-aachen.de"
                + hostBlocks githubIdentity config.sops.placeholder."git/private-git";
            };
        };

      provides.to-users.homeManager =
        {
          config,
          lib,
          osConfig,
          ...
        }:
        let
          gitKey = "${osConfig.host.sshKey}-git";
          githubIdentity = osConfig.sops.templates."git-github-identity".path;
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
              { path = osConfig.sops.templates."git-identity-includes".path; }
            ];
          };

          programs.ssh = {
            includes = lib.mkAfter [ osConfig.sops.templates."ssh-secret-hosts".path ];
            settings = {
              "github.com" = {
                AddKeysToAgent = "yes";
                IdentityFile = gitKey;
              };
              "codeberg.org" = {
                AddKeysToAgent = "yes";
                IdentityFile = gitKey;
              };
            };
          };
        };
    };
}
