# Assembles the NixOS systems from the class-keyed aspects in `aspects.nixos.*`
# and `aspects.home.*`. Hosts are composed by aspect *name*; each name resolves to
# its system module (if any) and its home module (if any), so a single name list
# pulls in both halves of a cross-cutting aspect. Home modules are attached once via
# `home-manager.users.<user>.imports`; since they are no longer lexically nested in
# their nixos module, `extraSpecialArgs` supplies inputs/username/systemname.
{ inputs, config, ... }:
let
  system = "x86_64-linux";
  username = "shochraos";

  nixosAspects = config.aspects.nixos or { };
  homeAspects = config.aspects.home or { };

  sysFor = names: map (n: nixosAspects.${n}) (builtins.filter (n: nixosAspects ? ${n}) names);
  homeFor = names: map (n: homeAspects.${n}) (builtins.filter (n: homeAspects ? ${n}) names);

  # Aspect bundles (mirror the former modules/*/default.nix groupings), by name.
  core = [
    "audio"
    "boot"
    "fonts"
    "git"
    "locale"
    "network"
    "ssh"
    "terminal"
    "user"
    "zed"
    "zen"
    "scheduling"
  ];
  nixConfig = [
    "nix"
    "home-manager"
  ];
  hyprland = [
    "config"
    "animations"
    "keybinds"
    "window_rules"
  ];
  desktop = hyprland ++ [
    "dms"
    "theme"
    "portal"
  ];
  gaming = [
    "lact"
    "mangohud"
    "nvidia"
    "packages"
    "steam"
    "sunshine"
  ];

  mkHost =
    name: names: pathModules:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs username;
        systemname = name;
      };
      modules = [
        inputs.home-manager.nixosModules.home-manager
        inputs.stylix.nixosModules.stylix
        nixosAspects.hostOptions
        {
          home-manager.extraSpecialArgs = {
            inherit inputs username;
            systemname = name;
          };
          home-manager.users.${username}.imports = homeFor names;
        }
      ]
      ++ pathModules
      ++ sysFor names;
    };
in
{
  flake.nixosConfigurations = {
    Azazel =
      mkHost "Azazel"
        (
          core
          ++ nixConfig
          ++ desktop
          ++ gaming
          ++ [
            "ai"
            "virtualization"

            "bluetooth"
            "cloud"
            "common-packages"
            "mpv"
            "sshfs"
            "office"
            "scanprint"
            "kde-connect"

            "amdpower"
            "gamechat"
            "inputremapper"
            "lgtv"
            "mp3tag"
            "preventsleep"
          ]
        )
        [
          ../../hosts/Azazel/hardware-configuration.nix
          ../../hosts/Azazel/filesystems.nix
          ../../hosts/Azazel/host-specific.nix
        ];

    Solas =
      mkHost "Solas"
        (
          core
          ++ nixConfig
          ++ desktop
          ++ [
            "virtualization"

            "bluetooth"
            "fprint"
            "cloud"
            "common-packages"
            "office"
            "scanprint"
            "kde-connect"

            "amdpower"
            "mic-mute"
          ]
        )
        [
          ../../hosts/Solas/hardware-configuration.nix
          ../../hosts/Solas/filesystems.nix
          ../../hosts/Solas/host-specific.nix
        ];
  };
}
