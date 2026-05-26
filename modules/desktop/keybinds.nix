{
  lib,
  username,
  ...
}:
let
  lua = lib.generators.mkLuaInline;
in
{
  home-manager.users.${username} =
    { config, pkgs, ... }:
    {
      wayland.windowManager.hyprland = {
        bind = [
          {
            _args = [
              "SUPER, Return"
              (lua "hl.dsp.exec_cmd(\"ghostty\")")
            ];
          }
          {
            _args = [
              "SUPER, F"
              (lua "hl.dsp.exec_cmd(\"nautilus\")")
            ];
          }
          {
            _args = [
              "SUPER, T"
              (lua "hl.dsp.exec_cmd(\"gnome-text-editor\")")
            ];
          }
          {
            _args = [
              "SUPER, Q"
              (lua "hl.dsp.killactive()")
            ];
          }
          {
            _args = [
              "SUPER CTRL, F"
              (lua "hl.dsp.fullscreen(0)")
            ];
          }
          {
            _args = [
              "SUPER ALT, F"
              (lua "hl.dsp.togglefloating()")
            ];
          }
          {
            _args = [
              "SUPER, left"
              (lua "hl.dsp.movefocus(\"l\")")
            ];
          }
          {
            _args = [
              "SUPER, right"
              (lua "hl.dsp.movefocus(\"r\")")
            ];
          }
          {
            _args = [
              "SUPER, up"
              (lua "hl.dsp.movefocus(\"u\")")
            ];
          }
          {
            _args = [
              "SUPER, down"
              (lua "hl.dsp.movefocus(\"d\")")
            ];
          }
          {
            _args = [
              "SUPER SHIFT, left"
              (lua "hl.dsp.movewindow(\"l\")")
            ];
          }
          {
            _args = [
              "SUPER SHIFT, right"
              (lua "hl.dsp.movewindow(\"r\")")
            ];
          }
          {
            _args = [
              "SUPER SHIFT, up"
              (lua "hl.dsp.movewindow(\"u\")")
            ];
          }
          {
            _args = [
              "SUPER SHIFT, down"
              (lua "hl.dsp.movewindow(\"d\")")
            ];
          }
          {
            _args = [
              "SUPER CTRL, left"
              (lua "hl.dsp.workspace(\"m-1\")")
            ];
          }
          {
            _args = [
              "SUPER CTRL, right"
              (lua "hl.dsp.workspace(\"m+1\")")
            ];
          }
          {
            _args = [
              "SUPER CTRL SHIFT, left"
              (lua "hl.dsp.movetoworkspace(\"-1\")")
            ];
          }
          {
            _args = [
              "SUPER CTRL SHIFT, right"
              (lua "hl.dsp.movetoworkspace(\"+1\")")
            ];
          }
          {
            _args = [
              "SUPER, L"
              (lua "hl.dsp.exec_cmd(\"dms ipc call lock lock\")")
            ];
          }
          {
            _args = [
              "PRINT"
              (lua "hl.dsp.exec_cmd(\"dms screenshot --no-file\")")
            ];
          }
          {
            _args = [
              "SUPER, PRINT"
              (lua "hl.dsp.exec_cmd(\"dms screenshot\")")
            ];
          }
          {
            _args = [
              "SUPER, Space"
              (lua "hl.dsp.exec_cmd(\"dms ipc call spotlight toggle\")")
            ];
          }
          {
            _args = [
              "SUPER, V"
              (lua "hl.dsp.exec_cmd(\"dms ipc call clipboard toggle\")")
            ];
          }
          {
            _args = [
              "SUPER, M"
              (lua "hl.dsp.exec_cmd(\"dms ipc call processlist focusOrToggle\")")
            ];
          }
          {
            _args = [
              "SUPER, N"
              (lua "hl.dsp.exec_cmd(\"dms ipc call notifications toggle\")")
            ];
          }
          {
            _args = [
              "SUPER, TAB"
              (lua "hl.dsp.exec_cmd(\"dms ipc call hypr toggleOverview\")")
            ];
          }

          {
            _args = [
              "SUPER, mouse:272"
              (lua "hl.dsp.movewindow()")
              { mouse = true; }
            ];
          }
          {
            _args = [
              "SUPER, mouse:273"
              (lua "hl.dsp.resizewindow()")
              { mouse = true; }
            ];
          }

          {
            _args = [
              "code:199"
              (lua "hl.dsp.sendshortcut(\"CTRL SHIFT, M, class:^(discord)$\")")
              { release = true; }
            ];
          }
          {
            _args = [
              "code:200"
              (lua "hl.dsp.sendshortcut(\"CTRL SHIFT, D, class:^(discord)$\")")
              { release = true; }
            ];
          }
          {
            _args = [
              "code:191"
              (lua "hl.dsp.exec_cmd(\"playerctl --player=spotify previous\")")
              { release = true; }
            ];
          }
          {
            _args = [
              "code:192"
              (lua "hl.dsp.exec_cmd(\"playerctl --player=spotify play-pause\")")
              { release = true; }
            ];
          }
          {
            _args = [
              "code:193"
              (lua "hl.dsp.exec_cmd(\"playerctl --player=spotify next\")")
              { release = true; }
            ];
          }

          {
            _args = [
              "code:201"
              (lua "hl.dsp.exec_cmd(\"playerctl --player=spotify volume 0.05-\")")
              { repeating = true; }
            ];
          }
          {
            _args = [
              "code:202"
              (lua "hl.dsp.exec_cmd(\"playerctl --player=spotify volume 0.05+\")")
              { repeating = true; }
            ];
          }
        ]
        ++ lib.optionals (config.modules.gamechat.isLoaded or false) [
          {
            _args = [
              "code:195"
              (lua "hl.dsp.exec_cmd(\"gamechat_game\")")
              { release = true; }
            ];
          }
          {
            _args = [
              "code:196"
              (lua "hl.dsp.exec_cmd(\"gamechat_chat\")")
              { release = true; }
            ];
          }
          {
            _args = [
              "code:197"
              (lua "hl.dsp.exec_cmd(\"gamechat_reset\")")
              { release = true; }
            ];
          }
        ]
        ++ lib.optionals (config.modules.lgtv.isLoaded or false) [
          {
            _args = [
              "SUPER ALT, Home"
              (lua "hl.dsp.exec_cmd(\"sudo ${pkgs.systemd}/bin/systemctl start wol-lgtv.service\")")
              { locked = true; }
            ];
          }
        ];
      };
    };
}
