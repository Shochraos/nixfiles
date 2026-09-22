{ config, ... }:
let
  inherit (config) assets;
in
{
  den.aspects.media.provides.to-users.homeManager =
    { pkgs, lib, ... }:
    let
      jellyfinSettings = pkgs.writeShellApplication {
        name = "jellyfin-settings";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.jq
        ];
        text = ''
          settings="''${XDG_CONFIG_HOME:-$HOME/.config}/jellyfin-mpv-shim/conf.json"
          overlay="${assets.jellyfinMpvShimConfig}"

          if [ ! -e "$settings" ]; then
            install -Dm644 "$overlay" "$settings"
            echo "jellyfin-settings: created $settings"
            exit 0
          fi

          if ! jq empty "$settings" >/dev/null 2>&1; then
            echo "jellyfin-settings: $settings is not valid JSON, leaving it untouched" >&2
            exit 0
          fi

          if jq -e --slurpfile overlay "$overlay" \
            '. as $live | $overlay[0] | to_entries | all(.value == $live[.key])' \
            "$settings" >/dev/null; then
            exit 0
          fi

          merged_file="$(mktemp "''${settings}.XXXXXX")"
          jq -s '.[0] * .[1]' "$settings" "$overlay" > "$merged_file"
          chmod --reference="$settings" "$merged_file"
          mv "$merged_file" "$settings"
          echo "jellyfin-settings: applied the nix-managed keys to $settings"
        '';
      };
    in
    {
      home.packages = [
        pkgs.jellyfin-mpv-shim
        jellyfinSettings
      ];

      programs.mpv = {
        enable = true;

        config = {
          vo = "gpu-next";
          target-colorspace-hint = "yes";
          osc = "no";
          border = "no";
        };

        scripts = with pkgs; [
          mpvScripts.uosc
          mpvScripts.thumbfast
          mpvScripts.mpris
        ];

        scriptOpts = {
          uosc = {
            controls = "menu,gap:0.5,<has_many_video>video,<has_many_audio>audio,<video,audio>subtitles,space,play-pause,space,<video,audio>gap:1.0,<has_many_audio>gap:1.0,<has_many_video>gap:1.0,gap:0.5,fullscreen";
            controls_size = 50;

            font_scale = 1.5;
            font_bold = true;
          };

          thumbfast = {
            network = "yes";
          };
        };
      };

      xdg.autostart = {
        entries = [
          "${pkgs.jellyfin-mpv-shim}/share/applications/jellyfin-mpv-shim.desktop"
        ];
      };

      home.activation.jellyfinSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        lib.getExe jellyfinSettings
      );

      xdg.configFile."mpv/scripts/auto-hdr.lua".text = ''
        local mp = require 'mp'

        local hdr_on = false

        local function set_hdr(state)
          if state == hdr_on then return end
          hdr_on = state
          mp.command_native({
            name = "subprocess",
            playback_only = false,
            args = { "hdr-set", state and "on" or "off" },
          })
        end

        mp.observe_property("video-params/gamma", "string", function(_, gamma)
          set_hdr(gamma == "pq" or gamma == "hlg")
        end)

        mp.register_event("shutdown", function() set_hdr(false) end)
      '';
    };
}
