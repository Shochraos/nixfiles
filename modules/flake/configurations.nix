{ inputs, config, lib, ... }:
let
  system = "x86_64-linux";
  username = "shochraos";

  containerUser = "containerUser";

  nixosAspects = config.aspects.nixos or { };
  homeAspects = config.aspects.home or { };
  containerAspects = config.aspects.containers or { };

  pick = set: names: map (n: set.${n}) (builtins.filter (n: set ? ${n}) names);
  sysFor = pick nixosAspects;
  homeFor = pick homeAspects;
  containersFor = pick containerAspects;

  base = [
    "boot"
    "nix"
    "locale"
    "network"
    "audio"
    "fonts"
    "scheduling"
    "user"
    "terminal"
    "remotes"
  ];

  desktop = base ++ [
    "hyprland"
    "dankshell"
    "browser"
    "editor"
    "apps"
    "sync"
    "kde-connect"
    "printing"
    "bluetooth"
  ];

  containers = [
    "quadlet"
    "proxy"
  ];

  mkHost =
    name: names:
    let
      containerModules = containersFor names;
      enableContainers = builtins.elem "quadlet" names && containerModules != [ ];
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs username;
        systemname = name;
      };
      modules = [
        inputs.home-manager.nixosModules.home-manager
        inputs.stylix.nixosModules.stylix
        inputs.quadlet-nix.nixosModules.quadlet
        nixosAspects.hostOptions
        {
          home-manager.extraSpecialArgs = {
            inherit inputs username;
            systemname = name;
          };
          home-manager.users.${username}.imports = homeFor names;
        }
      ]
      ++ sysFor names
      ++ lib.optional enableContainers {
        home-manager.users.${containerUser}.imports = containerModules;
      };
    };
in
{
  flake.nixosConfigurations = {
    Azazel = mkHost "Azazel" (
      desktop
      ++ containers
      ++ [
        "azazel"
        "cpu-amd"
        "gaming"
        "ai"
        "media"
        "remote-mounts"
        "virtualization"
        "gamechat"
        "inputremapper"
        "lgtv"
        "mp3tag"
        "preventsleep"
      ]
    );

    Solas = mkHost "Solas" (
      desktop
      ++ [
        "solas"
        "cpu-amd"
        "fingerprint"
        "virtualization"
        "mic-mute"
      ]
    );
  };
}
