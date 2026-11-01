# nixfiles

A NixOS + [home-manager](https://github.com/nix-community/home-manager) configuration for a complete Wayland desktop ([Hyprland](https://hyprland.org), [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell), [stylix](https://github.com/danth/stylix)), managed as one flake across two machines: **Azazel** (desktop / gaming) and **Solas** (laptop).

> **AI disclaimer:** Parts of this configuration and this README were written with AI assistance. Review anything you adopt before adding it to your own system.

## Before you use

> [!WARNING]
> This repository is **not designed to be used as is**. It may break your system if you rebuild without adjusting it first.

1. Replace the hardware configurations in `./modules/hosts/<host>/` with your own.
2. Review the package selections and settings.
3. Update the user and host names referenced throughout.

## Architecture

The tree follows the **dendritic pattern**: every file under `./modules/` is a [`flake-parts`](https://flake.parts) module, auto-imported by [`import-tree`](https://github.com/vic/import-tree). There is no central import list.

Hosts are assembled from **den aspects** ([denful/den](https://github.com/denful/den)). Feature modules register `den.aspects.<name>`, while `modules/flake/` also contains flake infrastructure. An aspect is a named bundle of NixOS and home-manager config, and `modules/flake/den.nix` wires those names into `base` → `graphical` → per-host includes, plus exactly one form-factor aspect. den forwards the home-manager half itself, with `osConfig` available. Shared modules never fork per host: they read `host.*` options, declared once in `modules/flake/options.nix`, that the host's `config.nix` fills in.

<details>
<summary>Architecture graph</summary>

![aspect graph: base is included by graphical, graphical by azazel and solas](assets/aspect-graph.svg)

</details>

> [!TIP]
> Adding a feature is two steps: define `den.aspects.<name>` in a file under `modules/`, then add `<name>` to an includes list in `modules/flake/den.nix`. A new file is invisible to the flake until it is git-tracked, so `git add -N` it before evaluating.

## Directory layout

- `./flake.nix` — entry point; auto-imports `./modules/`.
- `./modules/flake/` — assembly logic (`den.nix`, `options.nix`, `paths.nix`) plus the devshell, the treefmt gate and the aspect-graph check. Start here.
- `./modules/base/`, `./modules/graphical/`, `./modules/features/` — the aspect layers. A file's folder names the layer that includes it.
- `./modules/hosts/<host>/` — `config.nix` (`host.*` settings), `hardware.nix`, `filesystems.nix`.
- `./modules/users/` — per-user aspects, resolved by name.
- `./pkgs/<name>/package.nix` — packages nixpkgs lacks, reached through a named overlay in the owning aspect.
- `./configs/`, `./assets/` — raw config files, templates, scripts, patches, agent rules, and the rendered aspect graph with the script that draws it.
- `./secrets/` — [sops-nix](https://github.com/Mic92/sops-nix)-encrypted secrets.

## Development

```bash
nh-switch        # build and switch
nh-boot          # build and set as the boot default
nh-update        # update inputs, build, set as boot default

nix fmt          # format and lint: nixfmt, shfmt, shellcheck, statix, deadnix, actionlint
nix flake check  # formatting, linting and graph freshness
```

The only CI checks are formatting/linting and aspect-graph freshness, via `nix flake check`; application builds and runtime testing are separate. Local commit hooks remain installed and enabled. Verify affected package and host builds before switching. For evaluation only, use `nix flake check --no-build --option allow-import-from-derivation false`.

That SVG ships with the change that made it stale. The pre-commit hook redraws it and fails if the result differs from the index; it never stages files. In `nix develop`, run `python3 assets/scripts/draw-aspects.py 820`, review the result and stage it yourself. The devshell supplies Python and ripgrep and installs the local commit hooks. GitHub Actions runs `nix flake check` on pushes, pull requests and a weekly schedule. Action revisions are pinned to commits (checkout v7 and install-nix-action v31).

Secrets are encrypted at rest with SOPS. `sops edit secrets/secrets.yaml` decrypts values for the editor and re-encrypts them when saving, even with a scripted editor. Perform secret edits yourself with trusted tooling; never commit plaintext. Configuration consumes `config.sops.placeholder` or `.path` rather than reading secret values during evaluation.

## Runtime policies

- Remote shares are on-demand automounts with a 30-second mount timeout and five-minute idle unmount. A failed initial attempt does not block boot; later access can retry. Their existing SFTP trust and access policy is unchanged.
- Azazel waits for NetworkManager and retains its NVMe APST workaround. Solas skips wait-online and retains normal NVMe power saving.
- `hdr <foreground command> [arguments...]` owns HDR for the launched process group, forwards stop signals and waits before release. Use a foreground launch rather than a broker that starts a game in an unrelated process. It no longer guesses ownership from newly appearing window classes. mpv has its own PID-scoped lease. `hdr-set on` / `hdr-set off` control an independent manual lease; releasing one lease does not turn off another. DMS display settings remain untouched, and removing the last lease restores that baseline. Dead process leases are reaped within the 30-second timer interval.
- Calendar conflicts retain the existing `local wins` policy: the entire local item replaces its remote counterpart, not a field-level merge. Before resolving a disputed item, stop synchronization on both devices and preserve both copies. Recover the losing remote version from server version history or a backup before resuming.
- The NVIDIA-wide library paths remain in place because their runtime consumers have not been ruled out. The HDR launcher isolates compositor commands from that environment and restores it only for the game.

Workaround removal conditions are recorded in [WORKAROUNDS.md](WORKAROUNDS.md).

## License

[MIT](LICENSE) © 2026 Shochraos. The license covers the code in this repository; everything under `./secrets/` and any personal data is excluded.
