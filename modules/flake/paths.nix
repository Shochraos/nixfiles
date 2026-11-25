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
      amethystTemplate = ../../assets/templates/amethyst.json;
      atticEnqueueScript = ../../assets/scripts/attic-enqueue.sh;
      atticUploadScript = ../../assets/scripts/attic-upload.sh;
      btopConf = ../../configs/btop/btop.conf;
      discordTemplate = ../../assets/templates/discord.css;
      halloyTemplate = ../../assets/templates/halloy.toml;
      hermesDesktopArchivedCheckoutsPatch = ../../assets/patches/hermes-desktop-archived-checkouts.patch;
      hermesDesktopContextMeterPatch = ../../assets/patches/hermes-desktop-context-meter.patch;
      hermesDesktopRefinerTitlePatch = ../../assets/patches/hermes-desktop-refiner-title.patch;
      hermesDesktopSelectionOnlyPatch = ../../assets/patches/hermes-desktop-selection-only.patch;
      hermesDesktopTemplate = ../../assets/templates/hermes-desktop.js;
      hermesDesktopWorkspaceControlsPatch = ../../assets/patches/hermes-desktop-workspace-controls.patch;
      hdrStateScript = ../../assets/scripts/hdr-state.sh;
      hdrRunScript = ../../assets/scripts/hdr-run.sh;
      hsFuldaEduroamCa = ../../assets/certs/hs-fulda-eduroam-ca.pem;
      hyprlandModelessMonitorPatch = ../../assets/patches/hyprland-modeless-monitor.patch;
      ironyModManagerIcon = ../../assets/icons/ironymodmanager.png;
      keepassxcClassicThemePatch = ../../assets/patches/keepassxc-classic-theme.patch;
      klassyRc = ../../configs/klassy/klassyrc;
      kittyConf = ../../assets/kitty/kitty.conf;
      matugenFlylineTemplate = ../../assets/matugen/flyline.sh;
      matugenBtopTemplate = ../../assets/matugen/btop.theme;
      matugenStarshipTemplate = ../../assets/matugen/starship.toml;
      papirusPaletteTemplate = ../../assets/papirus-matugen/palette.txt.tpl;
      papirusRecolorScript = ../../assets/scripts/papirus-recolor.sh;
      jellyfinMpvShimConfig = ../../configs/jellyfin-mpv-shim/conf.json;
      micMuteScript = ../../assets/scripts/mic-mute.sh;
      mp3tagIcon = ../../assets/icons/mp3tag.png;
      samrewrittenIcon = ../../assets/icons/samrewritten.png;
      sopsFile = ../../secrets/secrets.yaml;
      spotifastTemplate = ../../assets/templates/spotifast.json.j2;
      steamvrCapabilitiesScript = ../../assets/scripts/steamvr-capabilities.py;
      steamTemplate = ../../assets/templates/steam.css;
      steamAccentsTemplate = ../../assets/templates/steam-accents.css;
      tutanotaTemplate = ../../assets/templates/tutanota.json;
      tutanotaMatugenScript = ../../assets/scripts/tutanota-matugen.sh;
    };

    packageSources = {
      blenderLabMcp = ../../pkgs/blender-lab-mcp/package.nix;
      bscpylgtv = ../../pkgs/bscpylgtv/package.nix;
      ironyModManager = ../../pkgs/irony-mod-manager/package.nix;
      mp3tag = ../../pkgs/mp3tag/package.nix;
      rea = ../../pkgs/rea/package.nix;
      tutanotaDesktop = ../../pkgs/tutanota-desktop/package.nix;
    };
  };
}
