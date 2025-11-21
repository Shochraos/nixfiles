# My personal nixfiles
This repository contains my personal Nix configuration files. It is designed to manage and automate the configuration of my environment across multiple machines.
It uses home-manager for user-level configuration and NixOS for system-level configuration. It also includes my opinionated selection of packages and settings.

## Structure:
- `./flake.nix`: Entry-point for the Nix flake. Loads the NixOS and home-manager configuration entry-points.
- `./configuration.nix`: Entry-point for the NixOS configuration.
- `./modules/*.nix`: Modularised NixOS configurations for system settings.
- `./home/home.nix`: Entry-point for the home-manager configuration.
- `./home/modules/*.nix`: Modularised home-manager configurations for user settings.
- `./home/plasma/plasma.nix`: Entry-point for the plasma-manager configuration.
- `./home/plasma/modules/*.nix`: Modularised plasma-manager configurations for plasma settings.
- `./hosts/[systemName]/*.nix`: Device-specific hardware-configurations.
- `./configs/*`: Contains package-specific configurations for which no home-manager module exists.
- `./assets/*`: Contains assets needed by the config like icons, etc.

## Before you use:
**This repository is not designed to be used as is!
It may break your system if you rebuild your system without adjusting it!
You need to change the following settings after you clone the repository:**

1. Adjust systemName(s) and `is[machineName]` expressions in the `Systems` section in `flake.nix` to match your machine(s).
2. Change the `lib.mkIf` and `++ lib.optionals` `is[machineName]` variable names in all `*.nix` files to your chosen variable names(s) if you changed them in Step 1.
3. Review and adjust all package selections and configurations to your liking.
4. Replace my hardware-configurations in `./hosts/[systemName]` with your own hardware configurations.