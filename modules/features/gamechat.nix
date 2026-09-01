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
      dms_plugin = inputs.game-chat-mix.packages.${pkgs.stdenv.hostPlatform.system}.dms_plugin;
    in
    {
      services.pipewire.pulse.enable = true;
      environment.systemPackages = with pkgs; [
        pulseaudio
      ];

      services.pipewire.wireplumber.extraConfig."99-gamechat-no-volume-restore" = {
        "stream.rules" = [
          {
            matches = [
              { "node.name" = "discord_sink"; }
              { "node.name" = "catchall_sink"; }
            ];
            actions.update-props."state.restore-props" = false;
          }
        ];
      };

      host.dms.plugins.gamechatMix = {
        enable = true;
        src = lib.mkForce "${dms_plugin}";
      };

      host.hyprland.keybinds = [
        {
          _args = [
            "code:195"
            (lua "hl.dsp.exec_cmd('dms ipc call gamechat game')")
            { release = true; }
          ];
        }
        {
          _args = [
            "code:196"
            (lua "hl.dsp.exec_cmd('dms ipc call gamechat chat')")
            { release = true; }
          ];
        }
        {
          _args = [
            "code:197"
            (lua "hl.dsp.exec_cmd('dms ipc call gamechat reset')")
            { release = true; }
          ];
        }
      ];
    };
}
