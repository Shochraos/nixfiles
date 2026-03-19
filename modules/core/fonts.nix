  { username, ... }:
  {
    home-manager.users.${username} =
    {
      fonts.fontconfig.enable = true;
    };
  }