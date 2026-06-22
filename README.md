# nixfiles

A NixOS + [home-manager](https://github.com/nix-community/home-manager) configuration that manages and automates a complete desktop environment across multiple machines. It uses [Hyprland](https://hyprland.org) as the compositor, [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) — a full [Quickshell](https://quickshell.org)-based desktop shell for Wayland compositors such as Hyprland and Niri — and [stylix](https://github.com/danth/stylix) for system-wide theming.

Two hosts are defined out of the box:

- **Azazel** — desktop / gaming.
- **Solas** — laptop.

## Architecture: the dendritic pattern

The configuration is built on the **dendritic pattern**: every module is a [`flake-parts`](https://flake.parts) module, and the entire `./modules` tree is auto-imported via [`import-tree`](https://github.com/vic/import-tree) (see `flake.nix`). There is no central list of files to import — dropping a `.nix` file anywhere under `modules/` automatically includes it in the flake evaluation.

### The aspect system

The core abstraction is an **aspect**: a named, deferred NixOS or home-manager module.

1. **`flake.nix`** declares `options.aspects` as a two-level attrset of deferred modules: `aspects.<class>.<name>`, where `class` is `nixos` or `home`.

2. **Every module under `modules/`** contributes by setting `aspects.nixos.<name>` and/or `aspects.home.<name>` to a module function. A single file commonly defines *both* the system and home sides of one feature:

   ```nix
   {
     aspects.nixos.user = { username, pkgs, ... }: { /* NixOS config */ };
     aspects.home.user  = { username, ... }:        { /* home-manager config */ };
   }
   ```

   These definitions are only *registered* — nothing is activated until a host selects the aspect by name.

3. **`modules/flake/configurations.nix`** assembles the hosts. It defines `base` and `desktop` name lists, then builds each `nixosSystem` by resolving the selected names into their matching `aspects.nixos.<name>` / `aspects.home.<name>` modules and wiring in stylix and home-manager.

> [!TIP]
> **Adding a feature is two steps:** (a) create a module file under `modules/` defining `aspects.{nixos,home}.<name>`, and (b) add `"<name>"` to the appropriate list (`base`, `desktop`, or a host's extra list) in `configurations.nix`. Forgetting step (b) means the file evaluates but the aspect is never applied.

### Host-specific overrides

Rather than forking shared modules per host, `modules/flake/options.nix` defines `host.*` NixOS options (e.g. `host.hyprland.*`, `host.dms.*`). Host modules *set* these, and shared home modules *read* them through `osConfig`.

## Directory layout

- `./flake.nix` — entry-point; declares `options.aspects` and auto-imports the `modules/` tree.
- `./modules/flake/` — the assembly logic (`configurations.nix`, `options.nix`). Start here to understand the wiring.
- `./modules/system/` — base OS aspects (`boot`, `nix`, `network`, `audio`, `user`, `terminal`, …).
- `./modules/desktop/` — Hyprland (`hypr-*`), the DankMaterialShell shell (`dankshell`), browser, apps.
- `./modules/features/` — opt-in aspects added per host (`gaming-*`, `ai`, `virtualization`, `media`, …).
- `./modules/hosts/<host>/` — `config.nix` (host overrides + `host.*` settings), `hardware.nix`, `filesystems.nix`.
- `./packages/` — local derivations consumed via `pkgs.callPackage`.
- `./configs/` — raw config files for tools without a home-manager module.
- `./assets/` — icons and static assets referenced by modules.

## Common commands

Rebuilds go through [`nh`](https://github.com/nix-community/nh) (the Nix helper), which is wrapped in a few shell aliases. Each alias targets the flake and the current host automatically:

```bash
# Build the configuration and switch to it now
nh-switch

# Build the configuration and set it as the boot default (applied on next boot)
nh-boot

# Update flake inputs, then build and set as the boot default
nh-update
```

Other useful commands:

```bash
# Check the flake evaluates
nix flake check

# Update inputs manually
nix flake update                          # all
nix flake lock --update-input nixpkgs     # one
```

## Before you use

> [!WARNING]
> This repository is **not designed to be used as is**. It may break your system if you rebuild without adjusting it first.

After cloning, you will need to:

1. Replace the hardware configurations in `./modules/hosts/<host>/` with your own.
2. Review and adjust all package selections and configurations to your liking.
3. Update the user and host names referenced throughout the configuration.
