{
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      feather
      electrum
    ];

    xdg.autostart = {
      entries = [
        "${pkgs.discord.desktopItem}/share/applications/discord.desktop"
        "${pkgs.spotify}/share/applications/spotify.desktop"
      ];
    };
  };
}
