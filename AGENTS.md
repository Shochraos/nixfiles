# Working in nixfiles

This flake defines four NixOS systems: Azazel (desktop), Solas (laptop), Seere and Sitri (headless servers). They share the base configuration and the `shochraos` Home Manager user. See [README.md](README.md) for setup and usage. Read [WORKAROUNDS.md](WORKAROUNDS.md) before changing a compatibility override; it records when the override can be removed.

## Where changes belong

- `flake.nix` declares inputs and uses import-tree to load `modules/`. Adding a module makes its definition available; it does not select the feature for a host. Select Den aspects through includes in `modules/flake/den.nix`, not through manual import lists or parallel enable flags.
- Extend the existing aspect in `modules/base/`, `modules/graphical/`, `modules/features/` or `modules/server/`. Keep machine-specific settings, hardware and storage under `modules/hosts/`, and user aspects under `modules/users/`. Use native NixOS and Home Manager options directly; reserve `host.*` options for data shared between aspects.
- When an aspect needs a Den functor, keep its argument non-destructured and define the functor only once at its attribute path. Bind library helpers at file scope, not as entity arguments in a `provides` chain.
- Register paths to `assets/`, `configs/` and local recipes in `pkgs/` through `modules/flake/paths.nix`. Consume `config.assets` or `config.packageSources` instead of duplicating relative paths. Edit a generator or its template rather than a generated config. Evaluation must not depend on files created at login or activation.
- Keep secrets encrypted. Use SOPS declarations, placeholders and runtime paths. Never decrypt, inspect, print or commit secret values; the owner supplies them.

## Development and verification

Use `nix develop` or the repository’s direnv environment. This provides the tools in `modules/flake/devshell.nix` and sets up the pre-commit runner for that checkout on that client. Keep development tools in the shell, not in a host’s system packages.

Use the locked inputs; change `flake.lock` only when an input update is in scope. Resolve pins through the root input references rather than guessing from lock node names. Keep Millennium’s pinned recipes scoped to gaming and Hermes Desktop on the root nixpkgs input. The Hermes backend is managed outside this repository.

For configuration changes, check the flake and evaluate each affected host. Replace `Azazel` below with the configuration name. Inspect the changed option as well as the host derivation, especially when a shared aspect serves several hosts.

```sh
nix flake check --no-build --no-write-lock-file --option allow-import-from-derivation false
nix eval --raw --no-write-lock-file --option allow-import-from-derivation false .#nixosConfigurations.Azazel.config.system.build.toplevel.drvPath
```

`nix fmt` can rewrite files; restrict it to files in scope. The pre-commit hook checks formatting without staging changes. CI runs the flake’s formatting and lint checks. A no-build evaluation neither runs those checks nor proves the system builds or boots. For documentation-only changes, verify links, paths and commands against their definitions; no system build is needed.

Use `ssh nix-workspace` for authorized builds. Default to no-build checks; run a full host build or rebuild only if requested for the task. The `nh-switch` and `nh-boot` helpers use `github:Shochraos/nixfiles/main`, not the working tree. A PR does not authorize deployment, activation or a service restart.

Even a connection test on `azazel` or `solas` needs prior approval naming the host, purpose and scope. Agent access there is limited to approved read-only diagnostics or scoped MCP operations: never install, activate, deploy or perform destructive operations on either host.

## Delivering changes

1. Treat planning, explanation and review as read-only. For implementation, start a fresh branch from the intended base before editing. Continue the same task on its branch while its PR is open; after merge or closure, start a new branch. Preserve unrelated work and existing staging.
2. The coordinating agent inspects the exact staged diff and commits only verified, task-owned changes. Workers do not commit or push. Make sure new Nix source files are tracked so the Git-backed flake can see them.
3. An implementation request includes pushing the verified branch and opening or updating its PR against the intended base. No separate push approval is needed unless the user limits delivery. Confirm the PR head matches the local commit and report its link and any verification gaps. Merging, rewriting history and publishing beyond that PR require explicit authorization.

Keep this root `AGENTS.md` in version control. Keep agent-only notes and handoffs out of commits; before writing them under `.hermes/`, verify the directory is ignored and the files are untracked.
