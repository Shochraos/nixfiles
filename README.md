# Shochraos' NixOS Configuration

## Summary

Personal NixOS and Home Manager configurations for Azazel (desktop), Solas (laptop), and Seere / Sitri (servers). The desktop environment uses Hyprland, DankMaterialShell and Stylix.

> **AI disclaimer:** Parts of this configuration and this README were written with AI assistance. Review anything you adopt before adding it to your own system.

## Installation

Start from an existing NixOS installation with flakes enabled. This configuration is specific to these machines; applying it unchanged can break your system.

1. Clone the repository:

   ```bash
   git clone https://github.com/Shochraos/nixfiles.git
   cd nixfiles
   ```

2. Adapt the host definitions under `modules/hosts/`, hardware and storage settings, user names, networking and checkout paths to your machine. Review the selected applications and services.
3. Configure your own SOPS recipients and encrypted secrets before applying the configuration. Never commit plaintext credentials.

After reviewing your changes, apply the configuration for your host. For example:

```bash
sudo nixos-rebuild switch --flake .#Azazel
```

Replace `Azazel` with the configuration name you adapted.

## Usage

The configured Bash shell provides these helpers:

| Command | Action |
| --- | --- |
| `nh-switch` | Build and switch to the configuration. |
| `nh-boot` | Build and select the configuration for the next boot. |
| `nh-update` | Update flake inputs, build and select the configuration for the next boot. |

Run `nix develop` for repository tooling. Use `nix fmt` to format and lint files, and `nix flake check` to run the formatting and lint checks. To check evaluation without building:

```bash
nix flake check --no-build --no-write-lock-file --option allow-import-from-derivation false
```

Evaluation alone does not verify builds or runtime behavior. Compatibility overrides and their removal conditions are documented in [WORKAROUNDS.md](WORKAROUNDS.md).

## Architecture

The flake uses flake-parts and import-tree to load its Nix modules. Den aspects combine a shared system baseline with the desktop features or server services selected for each host. Home Manager manages user applications and settings within the NixOS configuration.

Host definitions provide machine-specific hardware and storage settings. SOPS keeps secrets encrypted in the repository and supplies them at runtime.

## License

[Unlicense](UNLICENSE). The license covers the code in this repository; everything under `./secrets/` and any personal data is excluded.
