{
  den.aspects.gamechat.nixos =
    {
      pkgs,
      lib,
      ...
    }:
    let
      lua = lib.generators.mkLuaInline;
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
      services.pipewire.pulse.enable = true;
      environment.systemPackages = with pkgs; [
        pulseaudio
        gamechat_chat
        gamechat_game
        gamechat_reset
      ];

      host.hyprland.keybinds = [
        {
          _args = [
            "code:195"
            (lua "hl.dsp.exec_cmd('gamechat_game')")
            { release = true; }
          ];
        }
        {
          _args = [
            "code:196"
            (lua "hl.dsp.exec_cmd('gamechat_chat')")
            { release = true; }
          ];
        }
        {
          _args = [
            "code:197"
            (lua "hl.dsp.exec_cmd('gamechat_reset')")
            { release = true; }
          ];
        }
      ];
    };

  den.aspects.gamechat.provides.to-users.homeManager =
    { pkgs, ... }:
    let
      gamechat_mix = pkgs.writeShellScript "gamechat_mix.sh" (
        builtins.readFile ../../assets/scripts/gamechat_mix.sh
      );
    in
    {
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
}
