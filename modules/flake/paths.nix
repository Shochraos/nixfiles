{ lib, ... }:
let
  inherit (lib) mkOption types;
  pathTable = types.attrsOf types.path;
in
{
  options = {
    assets = mkOption {
      type = pathTable;
      default = { };
      description = "Repo data files and directories, resolved here so no feature file carries a relative-path literal.";
    };

    packageSources = mkOption {
      type = pathTable;
      default = { };
      description = "Package definitions under `pkgs/`, resolved here so no feature file carries a relative-path literal. Consumed by `callPackage`.";
    };
  };

  config = {
    assets = {
      discordTemplate = ../../assets/templates/discord.css;
      halloyTemplate = ../../assets/templates/halloy.toml;
      hermesSoul = ../../assets/harness-rules/hermes/SOUL.md;
      ironyModManagerIcon = ../../assets/icons/ironymodmanager.png;
      jellyfinMpvShimConfig = ../../configs/jellyfin-mpv-shim/conf.json;
      matugenSchemes = ../../configs/matugen;
      micMuteScript = ../../assets/scripts/mic-mute.sh;
      mp3tagIcon = ../../assets/icons/mp3tag.png;
      opencodeRules = ../../assets/harness-rules/opencode;
      quickshellIpcReconnectPatch = ../../assets/patches/quickshell-hyprland-ipc-reconnect.patch;
      xdphScreencopyBufferReusePatch = ../../assets/patches/xdph-screencopy-buffer-reuse.patch;
      samrewrittenIcon = ../../assets/icons/samrewritten.png;
      sopsFile = ../../secrets/secrets.yaml;
      spotifastTemplate = ../../assets/templates/spotifast.json.j2;
      steamTemplate = ../../assets/templates/steam.css;
    };

    packageSources = {
      bscpylgtv = ../../pkgs/bscpylgtv/package.nix;
      ironyModManager = ../../pkgs/irony-mod-manager/package.nix;
      mp3tag = ../../pkgs/mp3tag/package.nix;
      honchoServer = ../../pkgs/honcho-server/package.nix;
    };
  };
}
