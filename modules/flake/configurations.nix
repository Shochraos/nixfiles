{ inputs, config, ... }:
let
  system = "x86_64-linux";
  username = "shochraos";

  nixosAspects = config.aspects.nixos or { };
  homeAspects = config.aspects.home or { };

  pick = set: names: map (n: set.${n}) (builtins.filter (n: set ? ${n}) names);
  sysFor = pick nixosAspects;
  homeFor = pick homeAspects;

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
    "nextcloud"
  ];

  mkHost =
    name: names:
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
      ++ sysFor names;
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
