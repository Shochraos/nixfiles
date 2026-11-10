# Working in nixfiles

This repository configures four NixOS hosts with flake-parts, import-tree, Den aspects and Home Manager. Azazel and Solas use the graphical environment; Seere and Sitri are headless DNS/reverse-proxy hosts. All share the base configuration and the `shochraos` Home Manager user.

## Repository map

- `flake.nix`: inputs and the import-tree entry point. Keep its outputs minimal.
- `modules/flake/`: host/aspect composition in `den.nix`, shared data options in `options.nix`, repository paths in `paths.nix`, development tools and formatting.
- `modules/base/`: common system configuration.
- `modules/graphical/`: desktop configuration and applications.
- `modules/features/`: optional capabilities selected by hosts.
- `modules/server/`: independent server capabilities, explicitly selected per host; this directory is not an automatically enabled umbrella aspect.
- `modules/hosts/<host>/`: each host's `config.nix`, `hardware.nix` and `filesystems.nix`.
- `modules/users/`: user aspects, resolved by user name.
- `pkgs/`: local package recipes, exposed through `config.packageSources`.
- `assets/` and `configs/`: scripts, templates, patches and static configuration.
- `secrets/`: SOPS-encrypted data. `.sops.yaml` configures encryption recipients.

See `README.md` for the project overview and `WORKAROUNDS.md` before changing compatibility overrides.

## Development environment

Enter `nix develop`, or use the existing `.envrc` with direnv. The development shell supplies Nix language tools, linters, Python and repository hooks. Keep developer tooling in `devShells.default` or the consuming program's scope; never install it globally.

Use the locked inputs. Resolve input identities through `flake.lock`'s root input references, not similarly named transitive nodes. The `nh` commands use `github:Shochraos/nixfiles/main` and its published lock file. Do not move the local lock file unless explicitly requested. Keep both Millennium and Hermes Desktop following the root nixpkgs input.

## Configuration conventions

- Every Nix file under `modules/` is auto-imported as a flake-parts module. Define configuration through the appropriate Den aspect; do not add manual import lists or `default.nix` aggregators.
- Keep shared base, graphical and host composition in `modules/flake/den.nix`. A feature may own its dependency includes and scoped unfree allowances. Directory membership alone must not enable a capability.
- Extend the existing owner before creating another aspect. Package-only additions belong in an existing shared or per-host package list. Use directory aspects for multi-file capabilities and functors only for independent variation, not mutually exclusive features.
- Use includes for capability selection. Reserve typed `host.*` data for cross-aspect sharing or translation; do not add feature-enable booleans or aliases that merely forward native options. Put simple host-specific NixOS/Home Manager settings directly in the host configuration.
- Keep Den functor argument lambdas non-destructured and each functor as the sole definition at its attribute path. In provides-chain aspects, bind library helpers at file scope rather than treating them as entity arguments.
- Centralize repository-relative filesystem paths in `modules/flake/paths.nix`; consume `config.assets` and `config.packageSources` from file-level module arguments.
- Keep evaluation independent of runtime-generated files, including Matugen outputs. Do not run plugin setup scripts; integrate dependencies and configuration declaratively.
- Preserve native module ownership and existing behavior unless the task explicitly changes them. Keep workaround details in their existing documentation rather than adding investigation notes here.

## Verification workflow

For no-build evaluation, preserve the lock and disable import-from-derivation:

```bash
nix flake check --no-build --no-write-lock-file --option allow-import-from-derivation false
nix eval --raw --no-write-lock-file --option allow-import-from-derivation false .#nixosConfigurations.Azazel.config.system.build.toplevel.drvPath
```

Use the corresponding configuration name for Solas, Seere or Sitri. Evaluate affected hosts. For behavior-preserving changes, capture before/after toplevel derivations and relevant settings; explain any differences. Matching derivations do not establish runtime health.

Do not run system builds or rebuilds (`nix build`, `nixos-rebuild` or `nh` build/deploy helpers) unless the user explicitly instructs you to do so for the current task. Implementation requests and routine verification are not build authorization. Use formatting/linting and the no-build evaluation commands above by default; never omit `--no-build` from `nix flake check` without explicit build authorization. Report checks not performed.

`nix fmt` runs the configured formatters and linters and can modify files. Keep formatting within the authorized scope and preserve unrelated working changes. CI runs flake checks for formatting/linting, not full host builds or runtime tests.

Local hooks check formatting without staging files.

## Safety and change boundaries

- Do not stage, commit or push. New source files must be included in the Git-backed flake source before normal evaluation can see them; leave index changes to the owner and report omitted files.
- Keep root `AGENTS.md` in version control. Update it only when an approved change makes its repository guidance inaccurate; do not add task history, audit findings or code-line references.
- Never decrypt secrets or run `sops -d`. Declare secrets and consume SOPS placeholders or runtime paths; verify structure without reading plaintext. Secret-value edits belong to the owner.
- Ask before activation, switches, service restarts or disruptive tests. The `nh-switch` and `nh-boot` helpers build and/or deploy; they are not read-only verification commands.