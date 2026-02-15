{ username, ... }:
{
  home-manager.users.${username} =
  {
    programs.git =
    {
      enable = true;
      settings =
      {
        user.name  = "Shochraos";
        user.email = "github@shonline.slmail.me";
        core.excludesfile = "/home/${username}/.gitignore";
      };
    };
  };
}