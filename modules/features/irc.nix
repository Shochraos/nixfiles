{ lib, config, ... }:
let
  inherit (config) assets;
in
{
  den.aspects.irc =
    { user, ... }:
    {
      nixos =
        { config, pkgs, ... }:
        {
          sops.secrets = {
            "irc/one/nickname" = { };
            "irc/one/url" = { };
            "irc/one/nickserv_password".owner = user.name;
            "irc/one/irckey" = { };
            "irc/one/channels" = { };
            "irc/one/open-channels" = { };
          };

          sops.templates."halloy.toml" = {
            owner = user.name;
            file =
              (pkgs.formats.toml { }).generate "halloy-config"
                config.home-manager.users.${user.name}.programs.halloy.settings;
          };

          host.matugen.templates.halloy = {
            input_path = assets.halloyTemplate;
            output_path = "~/.config/halloy/themes/matugen.toml";
          };
        };

      provides.to-users.homeManager =
        { config, osConfig, ... }:
        let
          secret = name: osConfig.sops.placeholder."irc/one/${name}";
        in
        {
          programs.halloy = {
            enable = true;

            settings = {
              theme = "matugen";

              font = {
                family = osConfig.stylix.fonts.monospace.name;
                size = osConfig.stylix.fonts.sizes.applications;
              };

              servers.one = {
                nickname = secret "nickname";
                server = secret "url";
                port = 6697;
                use_tls = true;
                nick_password_file = osConfig.sops.secrets."irc/one/nickserv_password".path;
                on_connect = [
                  "/msg Drone enter ${secret "channels"} ${secret "nickname"} ${secret "irckey"}"
                  "/delay 1"
                  "/join ${secret "open-channels"}"
                ];
              };
            };
          };

          xdg.configFile."halloy/config.toml".source = lib.mkForce (
            config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."halloy.toml".path
          );
        };
    };
}
