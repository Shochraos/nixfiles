{
  aspects.nixos.remotes =
    {
      config,
      lib,
      systemname,
      username,
      ...
    }:
    {
      sops.secrets = {
        "ssh/hosts".owner = username;
        "ssh/private-git" = { };
        "ssh/uni-git" = { };
        "git/url-rewrites".owner = username;
      };

      sops.templates."ssh-git-hosts" = {
        owner = username;
        content = ''
          Host ${config.sops.placeholder."ssh/uni-git"}
            AddKeysToAgent yes
            IdentityFile /home/${username}/.ssh/${lib.toLower systemname}-git

          Host ${config.sops.placeholder."ssh/private-git"}
            AddKeysToAgent yes
            IdentityFile /home/${username}/.ssh/${lib.toLower systemname}-git
            Port 2222
        '';
      };
    };

  aspects.home.remotes =
    {
      lib,
      osConfig,
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
            IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}-git";
          };
          "codeberg.org" = {
            AddKeysToAgent = "yes";
            IdentityFile = "/home/${username}/.ssh/${lib.toLower systemname}-git";
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
