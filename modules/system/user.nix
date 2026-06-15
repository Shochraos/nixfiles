{
  aspects.nixos.user =
    { username, pkgs, ... }:
    {
      users.users.${username} = {
        isNormalUser = true;
        shell = pkgs.fish;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
      };

      programs.fish.enable = true;
    };

  aspects.home.user =
    { username, ... }:
    {
      home.username = username;
      home.homeDirectory = "/home/${username}";
    };
}
