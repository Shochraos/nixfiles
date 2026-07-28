# nixfiles

A NixOS + [home-manager](https://github.com/nix-community/home-manager) configuration that manages and automates a complete desktop environment across multiple machines. It uses [Hyprland](https://hyprland.org) as the compositor, [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) — a full [Quickshell](https://quickshell.org)-based desktop shell for Wayland compositors such as Hyprland and Niri — and [stylix](https://github.com/danth/stylix) for system-wide theming.

Two hosts are defined out of the box:

- **Azazel** — desktop / gaming.
- **Solas** — laptop.

## Architecture: the dendritic pattern

The configuration is built on the **dendritic pattern**: every module is a [`flake-parts`](https://flake.parts) module, and the entire `./modules` tree is auto-imported via [`import-tree`](https://github.com/vic/import-tree) (see `flake.nix`). There is no central list of files to import — dropping a `.nix` file anywhere under `modules/` automatically includes it in the flake evaluation.

### The aspect system

Host assembly is done by [denful/den](https://github.com/denful/den). Its core abstraction is a **den aspect**: a named bundle of per-class modules (NixOS on one side, home-manager on the other).

1. **Every module under `modules/`** contributes by setting `den.aspects.<name>`. A single file commonly defines *both* the system and home sides of one feature; aspects that need context are written as a function over `{ host, user }`:

   ```nix
   {
     den.aspects.foo =
       { host, user, ... }:
       {
         nixos = { pkgs, ... }: { /* NixOS config */ };
         provides.to-users.homeManager = { pkgs, ... }: { /* home-manager config */ };
       };
   }
   ```

   These definitions are only *registered*. An aspect becomes active in one of two ways: it is reachable from a host's includes graph, **or** its name matches an entity den resolves automatically — `den.hosts.<sys>.<H>.users.<u>` defaults to `den.aspects.<u>` (`nix/lib/entities/_types.nix`), and a missing one only produces a `lib.warn`. That is why the user aspect `shochraos` applies without appearing in any `includes` list.

2. **`modules/flake/den.nix`** assembles everything. It declares the hosts (`den.hosts.x86_64-linux.{Azazel,Solas}`, each with its user and an explicit host aspect) and the includes graph: `base` (core system aspects) is included by `graphical` (Hyprland, DankMaterialShell, terminal, browser, apps, …), which is included by the per-host aspects `azazel` / `solas` alongside exactly one form-factor aspect (`desktop` or `laptop`) and their opt-in features. Includes are **value references** (`den.aspects.<name>`), so a typo fails evaluation immediately instead of silently applying nothing.

3. **den wires home-manager automatically**: config from `provides.to-users.homeManager` lands in `home-manager.users.<name>`, with `osConfig` available in home modules. There is no hand-written glue between the system and home sides.

> [!TIP]
> **Adding a feature is two steps:** (a) create a module file under `modules/` defining `den.aspects.<name>`, and (b) add `<name>` to the appropriate includes list (`base`, `graphical`, or a host's list) in `modules/flake/den.nix`. Forgetting step (b) means the file evaluates but the aspect is never applied — **unless** its name is one den resolves automatically for an entity (see above), in which case it applies with no `includes` entry at all. Note also that a new file is invisible to `import-tree` until it is git-tracked: run `git add -N` on it before evaluating.

### Host-specific overrides

Rather than forking shared modules per host, `modules/flake/options.nix` defines `host.*` NixOS options (e.g. `host.hyprland.*`, `host.dms.*`). Host modules *set* these, and shared home modules *read* them through `osConfig`.

## Directory layout

- `./flake.nix` — entry-point; auto-imports the `modules/` tree via `import-tree`.
- `./modules/flake/` — the assembly logic (`den.nix`, `options.nix`). Start here to understand the wiring.
- `./modules/system/` — base OS aspects (`boot`, `nix`, `network`, `audio`, `shell`, `scheduling`, …) plus the form-factor aspects `desktop` / `laptop`; included via `base` or directly by a host.
- `./modules/users/` — per-user aspects, one file per user named after that user (`shochraos.nix`). Resolved by **name**, not through `includes`.
- `./modules/desktop/` — Hyprland (`hyprland/`), the DankMaterialShell shell (`dankshell`), terminal, browser, apps; included via `graphical`.
- `./modules/features/` — opt-in aspects added per host (`gaming/`, `ai`, `virtualization`, `media`, …).
- `./modules/hosts/<host>/` — `config.nix` (host overrides + `host.*` settings), `hardware.nix`, `filesystems.nix`.
- `./configs/` — raw config files for tools without a home-manager module.
- `./assets/` — icons and static assets referenced by modules.
- `./secrets/` — [sops-nix](https://github.com/Mic92/sops-nix)-encrypted secrets.

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
