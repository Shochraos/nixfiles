# Assembles the NixOS systems from the leaf aspects registered in `aspects.*`.
# Composition lives here (in the nixosConfigurations option) rather than in
# composite aspects: reading `config.aspects` from a *different* option is a
# normal cross-option reference, whereas one `aspects` entry importing another
# would be an unresolvable self-reference under `deferredModule`. specialArgs
# (inputs, username, systemname) are preserved exactly as in the pre-dendritic
# flake.
{ inputs, config, ... }:
let
  system = "x86_64-linux";
  username = "shochraos";
  m = config.aspects;

  # Aspect bundles (mirror the former modules/*/default.nix groupings).
  core = [
    m.audio
    m.boot
    m.fonts
    m.git
    m.locale
    m.network
    m.ssh
    m.terminal
    m.user
    m.zed
    m.zen
    m.scheduling
  ];
  nixConfig = [
    m.nix
    m.home-manager
  ];
  hyprland = [
    m.config
    m.animations
    m.keybinds
    m.window_rules
  ];
  desktop = hyprland ++ [
    m.dms
    m.theme
    m.portal
  ];
  gaming = [
    m.lact
    m.mangohud
    m.nvidia
    m.packages
    m.steam
    m.sunshine
  ];

  base = [
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
    m.hostOptions
  ];

  mkHost =
    name: modules:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs username;
        systemname = name;
      };
      modules = base ++ modules;
    };
in
{
  flake.nixosConfigurations = {
    Azazel = mkHost "Azazel" (
      [
        ../../hosts/Azazel/hardware-configuration.nix
        ../../hosts/Azazel/filesystems.nix
        ../../hosts/Azazel/host-specific.nix
      ]
      ++ core
      ++ nixConfig
      ++ desktop
      ++ gaming
      ++ [
        m.ai
        m.virtualization
      ]
      ++ [
        m.bluetooth
        m.cloud
        m.common-packages
        m.mpv
        m.sshfs
        m.office
        m.scanprint
        m.kde-connect
      ]
      ++ [
        m.amdpower
        m.gamechat
        m.inputremapper
        m.lgtv
        m.mp3tag
        m.preventsleep
      ]
    );

    Solas = mkHost "Solas" (
      [
        ../../hosts/Solas/hardware-configuration.nix
        ../../hosts/Solas/filesystems.nix
        ../../hosts/Solas/host-specific.nix
      ]
      ++ core
      ++ nixConfig
      ++ desktop
      ++ [
        m.virtualization
      ]
      ++ [
        m.bluetooth
        m.fprint
        m.cloud
        m.common-packages
        m.office
        m.scanprint
        m.kde-connect
      ]
      ++ [
        m.amdpower
        m.mic-mute
      ]
    );
  };
}
