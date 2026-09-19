{ lib, ... }:
let
  streamingWindowRules =
    streaming:
    lib.optional (streaming.displays != { }) {
      match = {
        class = "^(gamescope)$";
      };
      fullscreen = true;
    };

  streamingEnsureScript =
    { pkgs, streaming }:
    let
      displays = builtins.attrValues streaming.displays;

      lines = builtins.concatStringsSep "\n" (
        map (
          entry:
          let
            geometry = lib.optionalString (entry.scale != null) ", scale = ${entry.scale}";
          in
          ''
            if ! hyprctl monitors -j 2>/dev/null | jq -r '.[].name' | grep -qxF "${entry.output}"; then
              hyprctl output create headless "${entry.output}" >/dev/null 2>&1 || true
            fi
            hyprctl eval 'hl.monitor({ output = "${entry.output}", mode = "${entry.mode}"${geometry} })' >/dev/null 2>&1 || true
          ''
        ) displays
      );
    in
    if displays == [ ] then
      null
    else
      pkgs.writeShellApplication {
        name = "streaming-displays";
        runtimeInputs = with pkgs; [
          gnugrep
          jq
        ];
        text = lines;
      };

  streamingLua =
    script:
    lib.optionalString (script != null) ''
      local function ensure_streaming_displays()
        hl.timer(function()
          hl.exec_cmd("${script}/bin/streaming-displays")
        end, {
          timeout = 500,
          type = "oneshot",
        })
      end

      hl.on("hyprland.start", ensure_streaming_displays)
      hl.on("config.reloaded", ensure_streaming_displays)
    '';
in
{
  den.aspects.hyprland.provides.to-users.homeManager =
    {
      osConfig,
      pkgs,
      ...
    }:
    let
      streamingScript = streamingEnsureScript {
        inherit pkgs;
        streaming = osConfig.host.streaming;
      };
    in
    {
      home.packages = lib.optional (streamingScript != null) streamingScript;

      wayland.windowManager.hyprland = {
        settings = {
          window_rule = [
            {
              match = {
                class = "^(xdg-desktop-portal-gtk)$";
              };
              float = true;
            }
            {
              match = {
                class = "^(org.quickshell)$";
              };
              float = true;
            }
            {
              match = {
                class = "^(valent)$";
              };
              float = true;
            }
            {
              match = {
                class = "^(com.nextcloud.desktopclient.nextcloud)$";
              };
              float = true;
            }
          ]
          ++ osConfig.host.hyprland.windowRules
          ++ streamingWindowRules osConfig.host.streaming;

          layer_rule = [
            {
              match = {
                namespace = "^(dms.*)$";
              };
              ignore_alpha = 0;
              blur = true;
              no_anim = true;
            }
          ];
        };

        extraConfig = streamingLua streamingScript;
      };
    };
}
