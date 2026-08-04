{ inputs, ... }:
{
  den.aspects.gamechat.nixos =
    {
      pkgs,
      lib,
      ...
    }:
    let
      lua = lib.generators.mkLuaInline;
      gamechat_balance =
        inputs.game-chat-mix.packages.${pkgs.stdenv.hostPlatform.system}.gamechat_balance;
    in
    {
      services.pipewire.pulse.enable = true;
      environment.systemPackages = with pkgs; [
        pulseaudio
        gamechat_balance
      ];

      host.hyprland.keybinds = [
        {
          _args = [
            "code:195"
            (lua "hl.dsp.exec_cmd('gamechat_balance game')")
            { release = true; }
          ];
        }
        {
          _args = [
            "code:196"
            (lua "hl.dsp.exec_cmd('gamechat_balance chat')")
            { release = true; }
          ];
        }
        {
          _args = [
            "code:197"
            (lua "hl.dsp.exec_cmd('gamechat_balance reset')")
            { release = true; }
          ];
        }
      ];
    };

  den.aspects.gamechat.provides.to-users.homeManager =
    { lib, pkgs, ... }:
    let
      gamechat_mix = inputs.game-chat-mix.packages.${pkgs.stdenv.hostPlatform.system}.gamechat_mix;
    in
    {
      systemd.user.services.gamechat-mix = {
        Unit = {
          Description = "Dynamically sorts audio streams into sinks to independently manage volume";
          PartOf = [ "graphical-session.target" ];
          Wants = [ "pipewire-pulse.service" ];
          After = [ "pipewire-pulse.service" ];
        };

        Service = {
          Type = "simple";
          ExecStart = lib.getExe gamechat_mix;
          Restart = "always";
          RestartSec = 5;
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
