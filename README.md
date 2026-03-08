# My personal nixfiles
This repository contains my personal Nix configuration files. It is designed to manage and automate the configuration of my environment across multiple machines.
It uses home-manager for user-level configuration, plasma-manager for KDE Plasma configuration and NixOS for system-level configuration. It also includes my opinionated selection of packages and settings.

## Structure:
- `./flake.nix`: Entry-point for the Nix flake. Loads the NixOS and home-manager configuration entry-points.
- `./modules/`: System modules and configurations. Each module is self-sufficient and can be loaded as is. Some are grouped in logical "bundles" highlighted by the present default.nix file
- `./hosts/`: Device-specific hardware and software-configurations. Also includes module overrides for various module settings.
- `./configs/*`: Contains package-specific configurations for which no home-manager module exists.
- `./assets/*`: Contains assets needed by the config like icons, etc.

## Before you use:
**This repository is not designed to be used as is!
It may break your system if you rebuild your system without adjusting it!
You need to change the following settings after you clone the repository:**

1. Replace my hardware-configurations in `./hosts/[systemName]` with your own hardware configurations.
2. Review and adjust all package selections and configurations to your liking.