{
  den.aspects.hyprland.provides.to-users.homeManager =
    {
      lib,
      osConfig,
      ...
    }:
    let
      lua = lib.generators.mkLuaInline;
    in
    {
      wayland.windowManager.hyprland.settings = {
        bind = [
          {
            _args = [
              "SUPER + Return"
              (lua "hl.dsp.exec_cmd('ghostty')")
            ];
          }
          {
            _args = [
              "SUPER + F"
              (lua "hl.dsp.exec_cmd('nautilus')")
            ];
          }
          {
            _args = [
              "SUPER + T"
              (lua "hl.dsp.exec_cmd('gnome-text-editor')")
            ];
          }
          {
            _args = [
              "SUPER + Q"
              (lua "hl.dsp.window.close()")
            ];
          }
          {
            _args = [
              "SUPER + CTRL + Q"
              (lua "hl.dsp.window.kill()")
            ];
          }
          {
            _args = [
              "SUPER + CTRL + F"
              (lua "hl.dsp.window.fullscreen()")
            ];
          }
          {
            _args = [
              "SUPER + ALT + F"
              (lua "hl.dsp.window.float({ action = 'toggle' })")
            ];
          }
          {
            _args = [
              "SUPER + left"
              (lua "hl.dsp.focus({ direction = 'left' })")
            ];
          }
          {
            _args = [
              "SUPER + right"
              (lua "hl.dsp.focus({ direction = 'right' })")
            ];
          }
          {
            _args = [
              "SUPER + up"
              (lua "hl.dsp.focus({ direction = 'up' })")
            ];
          }
          {
            _args = [
              "SUPER + down"
              (lua "hl.dsp.focus({ direction = 'down' })")
            ];
          }
          {
            _args = [
              "SUPER + SHIFT + left"
              (lua "hl.dsp.window.move({ direction = 'left' })")
            ];
          }
          {
            _args = [
              "SUPER + SHIFT + right"
              (lua "hl.dsp.window.move({ direction = 'right' })")
            ];
          }
          {
            _args = [
              "SUPER + SHIFT + up"
              (lua "hl.dsp.window.move({ direction = 'up' })")
            ];
          }
          {
            _args = [
              "SUPER + SHIFT + down"
              (lua "hl.dsp.window.move({ direction = 'down' })")
            ];
          }
          {
            _args = [
              "SUPER + CTRL + left"
              (lua "hl.dsp.focus({ workspace = 'm-1' })")
            ];
          }
          {
            _args = [
              "SUPER + CTRL + right"
              (lua "hl.dsp.focus({ workspace = 'm+1' })")
            ];
          }
          {
            _args = [
              "SUPER + CTRL + SHIFT + left"
              (lua "hl.dsp.window.move({ workspace = '-1' })")
            ];
          }
          {
            _args = [
              "SUPER + CTRL + SHIFT + right"
              (lua "hl.dsp.window.move({ workspace = '+1' })")
            ];
          }
          {
            _args = [
              "SUPER + L"
              (lua ''
                function()
                  hl.dispatch(hl.dsp.exec_cmd('dms ipc call lock lock'))
                  hl.timer(function()
                    hl.dispatch(hl.dsp.dpms({ action = "disable" }))
                  end, {timeout = 500, type = "oneshot"})
                end
              '')
            ];
          }
          {
            _args = [
              "code:202"
              (lua "hl.dsp.exec_cmd('dms screenshot --no-file')")
            ];
          }
          {
            _args = [
              "SUPER + code:202"
              (lua "hl.dsp.exec_cmd('dms screenshot')")
            ];
          }
          {
            _args = [
              "SUPER + Space"
              (lua "hl.dsp.exec_cmd('dms ipc call spotlight toggle')")
            ];
          }
          {
            _args = [
              "SUPER + V"
              (lua "hl.dsp.exec_cmd('dms ipc call clipboard toggle')")
            ];
          }
          {
            _args = [
              "SUPER + M"
              (lua "hl.dsp.exec_cmd('dms ipc call processlist focusOrToggle')")
            ];
          }
          {
            _args = [
              "SUPER + N"
              (lua "hl.dsp.exec_cmd('dms ipc call notifications toggle')")
            ];
          }
          {
            _args = [
              "SUPER + TAB"
              (lua "hl.dsp.exec_cmd('dms ipc call hypr toggleOverview')")
            ];
          }

          {
            _args = [
              "SUPER + mouse:272"
              (lua "hl.dsp.window.drag()")
              { mouse = true; }
            ];
          }
          {
            _args = [
              "SUPER + mouse:273"
              (lua "hl.dsp.window.resize()")
              { mouse = true; }
            ];
          }

          {
            _args = [
              "code:199"
              (lua "hl.dsp.exec_cmd('dms ipc call discord toggleMute')")
            ];
          }
          {
            _args = [
              "code:200"
              (lua "hl.dsp.exec_cmd('dms ipc call discord toggleDeafen')")
            ];
          }
          {
            _args = [
              "code:191"
              (lua "hl.dsp.exec_cmd('dms ipc call mpris previous')")
              { release = true; }
            ];
          }
          {
            _args = [
              "code:192"
              (lua "hl.dsp.exec_cmd('dms ipc call mpris playPause')")
              { release = true; }
            ];
          }
          {
            _args = [
              "code:193"
              (lua "hl.dsp.exec_cmd('dms ipc call mpris next')")
              { release = true; }
            ];
          }
        ]
        ++ osConfig.host.hyprland.keybinds;
      };
    };
}
