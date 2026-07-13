{
  aspects.nixos.user =
    {
      username,
      pkgs,
      config,
      ...
    }:
    {
      users.mutableUsers = false;

      users.users.${username} = {
        isNormalUser = true;
        shell = pkgs.fish;
        hashedPasswordFile = config.sops.secrets."user-password-hash".path;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
      };

      users.users.root.hashedPasswordFile = config.sops.secrets."user-password-hash".path;

      programs.fish.enable = true;
    };

  aspects.home.user =
    { username, ... }:
    {
      home.username = username;
      home.homeDirectory = "/home/${username}";
    };
}
