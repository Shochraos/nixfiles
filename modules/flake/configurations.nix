{ inputs, config, ... }:
let
  system = "x86_64-linux";
  username = "shochraos";

  nixosAspects = config.aspects.nixos or { };
  homeAspects = config.aspects.home or { };

  sysFor = names: map (n: nixosAspects.${n}) (builtins.filter (n: nixosAspects ? ${n}) names);
  homeFor = names: map (n: homeAspects.${n}) (builtins.filter (n: homeAspects ? ${n}) names);

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
