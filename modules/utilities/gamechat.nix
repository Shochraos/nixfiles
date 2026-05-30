{
  pkgs,
  lib,
  username,
  ...
}:
let
  gamechat_mix = pkgs.writeShellScript "gamechat_mix.sh" (
    builtins.readFile ../../assets/scripts/gamechat_mix.sh
  );
  gamechat_chat = pkgs.writeShellScriptBin "gamechat_chat" (
    builtins.readFile ../../assets/scripts/gamechat_chat.sh
  );
  gamechat_game = pkgs.writeShellScriptBin "gamechat_game" (
    builtins.readFile ../../assets/scripts/gamechat_game.sh
  );
  gamechat_reset = pkgs.writeShellScriptBin "gamechat_reset" (
    builtins.readFile ../../assets/scripts/gamechat_reset.sh
  );
in
{
  options.modules.gamechat.isLoaded = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };
  config = {
    services.pipewire.pulse.enable = true;
    environment.systemPackages = with pkgs; [
      pulseaudio
      gamechat_chat
      gamechat_game
      gamechat_reset
    ];

    home-manager.users.${username} = {
      systemd.user.services.gamechat-mix = {
        Unit = {
          Description = "Dynamically sorts audio streams into sinks to independently manage volume";
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${gamechat_mix}";
          Restart = "always";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
  };
}
