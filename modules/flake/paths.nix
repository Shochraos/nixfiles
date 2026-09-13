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

    helpers = mkOption {
      type = pathTable;
      default = { };
      description = "Pure helper functions shared by aspects, resolved here so no aspect carries a relative-path literal.";
    };

    tests = mkOption {
      type = pathTable;
      default = { };
      description = "Test suites and script test scripts, resolved here so the flake module that wires the checks carries no relative-path literal.";
    };
  };

  config = {
    assets = {
      discordTemplate = ../../assets/templates/discord.css;
      halloyTemplate = ../../assets/templates/halloy.toml;
      ironyModManagerIcon = ../../assets/icons/ironymodmanager.png;
      jellyfinMpvShimConfig = ../../configs/jellyfin-mpv-shim/conf.json;
      matugenSchemes = ../../configs/matugen;
      micMuteScript = ../../assets/scripts/mic-mute.sh;
      mp3tagIcon = ../../assets/icons/mp3tag.png;
      ompRules = ../../assets/omp/rules;
      quickshellIpcReconnectPatch = ../../assets/patches/quickshell-hyprland-ipc-reconnect.patch;
      samrewrittenIcon = ../../assets/icons/samrewritten.png;
      sopsFile = ../../secrets/secrets.yaml;
      spicetifyTemplate = ../../assets/templates/spicetify.json.j2;
      steamTemplate = ../../assets/templates/steam.css;
    };

    packageSources = {
      bscpylgtv = ../../pkgs/bscpylgtv/package.nix;
      ironyModManager = ../../pkgs/irony-mod-manager/package.nix;
      mp3tag = ../../pkgs/mp3tag/package.nix;
    };

    helpers = {
      audio = ../../lib/audio.nix;
      display = ../../lib/display.nix;
    };

    tests = {
      ai = ../../modules/features/ai.nix;
      dir = ../../tests;
      options = ../../modules/flake/options.nix;
      scripts = ../../tests/scripts;
    };
  };
}
