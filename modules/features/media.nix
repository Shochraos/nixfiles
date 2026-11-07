{ config, den, ... }:
let
  inherit (config) assets;
in
{
  den.aspects.media.includes = with den.aspects; [ hdr ];

  den.aspects.media.provides.to-users.homeManager =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    {
      services.jellyfin-mpv-shim = {
        enable = true;
        settings = builtins.fromJSON (builtins.readFile assets.jellyfinMpvShimConfig);
      };
      home.packages = [ config.services.jellyfin-mpv-shim.package ];
      systemd.user.services.jellyfin-mpv-shim.Install.WantedBy = lib.mkForce (
        lib.optional (builtins.elem "jellyfin" osConfig.host.autostart) "graphical-session.target"
      );

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

      xdg.configFile."mpv/scripts/auto-hdr.lua".text = ''
        local mp = require 'mp'
        local utils = require 'mp.utils'

        local hdr_pid = utils.getpid()
        local hdr_owner = "mpv-" .. tostring(hdr_pid)

        local function set_hdr(state)
          mp.command_native({
            name = "subprocess",
            playback_only = false,
            args = { "hdr-set", state and "on" or "off", hdr_owner, tostring(hdr_pid) },
          })
        end

        mp.observe_property("video-params/gamma", "string", function(_, gamma)
          if gamma == nil then return end
          set_hdr(gamma == "pq" or gamma == "hlg")
        end)

        mp.register_event("shutdown", function() set_hdr(false) end)
      '';
    };
}
