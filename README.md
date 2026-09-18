# nixfiles

A NixOS + [home-manager](https://github.com/nix-community/home-manager) configuration that manages and automates a complete desktop environment across multiple machines. It uses [Hyprland](https://hyprland.org) as the compositor, [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (a full [Quickshell](https://quickshell.org)-based desktop shell for Wayland compositors such as Hyprland and Niri) and [stylix](https://github.com/danth/stylix) for system-wide theming.

Two hosts are defined out of the box:

- **Azazel** — desktop / gaming.
- **Solas** — laptop.

> **AI disclaimer:** Parts of this configuration and this README were written with AI assistance. Review anything you adopt before adding it to your own system.

## Before you use

> [!WARNING]
> This repository is **not designed to be used as is**. It may break your system if you rebuild without adjusting it first.

After cloning, you will need to:

1. Replace the hardware configurations in `./modules/hosts/<host>/` with your own.
2. Review and adjust all package selections and configurations to your liking.
3. Update the user and host names referenced throughout the configuration.

## Architecture

The configuration is built on the **dendritic pattern**: every module is a [`flake-parts`](https://flake.parts) module, and the entire `./modules` tree is auto-imported via [`import-tree`](https://github.com/vic/import-tree) (see `flake.nix`). There is no central list of files to import: a `.nix` file dropped anywhere under `modules/` is picked up.

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

   These definitions are only *registered*. An aspect becomes active in one of two ways: it is reachable from a host's includes graph, **or** its name matches an entity den resolves automatically. `den.hosts.<sys>.<H>.users.<u>` defaults to `den.aspects.<u>` (`nix/lib/entities/_types.nix`), and a missing one only produces a `lib.warn`. That is why the user aspect `shochraos` applies without appearing in any `includes` list.

2. **`modules/flake/den.nix`** assembles everything. It declares the hosts (`den.hosts.x86_64-linux.{Azazel,Solas}`, each with its user and an explicit host aspect) and the includes graph: `base` (core system aspects) is included by `graphical` (Hyprland, DankMaterialShell, terminal, browser, apps, …), which is included by the per-host aspects `azazel` / `solas` alongside exactly one form-factor aspect (`desktop` or `laptop`) and their opt-in features. Includes are **value references** (`den.aspects.<name>`), so a typo fails evaluation immediately instead of silently applying nothing.

3. **den wires home-manager automatically**: config from `provides.to-users.homeManager` lands in `home-manager.users.<name>`, with `osConfig` available in home modules. There is no hand-written glue between the system and home sides.

> [!TIP]
> **Adding a feature is two steps:** (a) create a module file under `modules/` defining `den.aspects.<name>`, and (b) add `<name>` to the appropriate includes list (`base`, `graphical`, or a host's list) in `modules/flake/den.nix`. Forgetting step (b) means the file evaluates but the aspect is never applied. If its name is one den resolves automatically for an entity (see above), it applies with no `includes` entry at all. A new file is invisible to `import-tree` until it is git-tracked: run `git add -N` on it before evaluating.

### Host-specific overrides

Rather than forking shared modules per host, `modules/flake/options.nix` defines `host.*` NixOS options (e.g. `host.hyprland.*`, `host.dms.*`). Host modules *set* these, and shared home modules *read* them through `osConfig`.

### Game streaming

Streaming to a handheld or headset over Steam Remote Play sends whatever the host displays. This desktop's real outputs are a 3440x1440 ultrawide and a 4K TV, so a client sees an aspect and pixel count nobody chose, and a game's own resolution list follows the host display.

`host.streaming.displays` declares one entry per streaming client. Each entry generates two commands: a `<name>-display` helper that owns the output name and mode, and a `<name>` launch-option wrapper that runs the game. Azazel declares `frame` (2560x1440@120) and `deck` (1280x800@90). Put the wrapper in a shortcut's launch options in place of `%command%`:

```
deck %command%
```

The displays are **permanent**. The hyprland aspect creates each one at compositor start and re-applies its mode on every reload, because a reload collapses a headless output back to `1920x1080@60` at scale 2. Permanence is what makes a display selectable: the portal's picker lists the outputs that currently exist, so a display created only while a game runs can never be chosen, and it must still be there when capture starts.

Leave the picker's restore checkbox unticked, so the portal stores no selection and asks again on every remote stream request. Ticking it is the trap. The portal keeps a selection as an output *name* and re-uses it while an output with that name exists, so one remembered choice for a real monitor outlives every later streaming session and captures that monitor instead of the streaming display. Clear one with:

```
gdbus call --session --dest org.freedesktop.impl.portal.PermissionStore \
  --object-path /org/freedesktop/impl/portal/PermissionStore \
  --method org.freedesktop.impl.portal.PermissionStore.Delete screencast <token>
```

`...PermissionStore.List screencast` names the tokens. A stale token left on the client side is harmless: the portal drops an unrecognised one and prompts.

Placement cannot be left to a rule. One window rule matches gamescope's own class and makes it fullscreen, but a rule cannot tell two displays apart when the class is identical, and a `monitor` field on a window rule is silently ignored because that field only exists for workspace rules. The compositor instead places a new window on whatever monitor has focus when it appears, which is unreliable during a launch: the screen-share picker and Steam itself can take focus in the seconds before the game maps, and the game then lands on a real monitor while the portal captures the streaming display. So the wrapper focuses its display's monitor before launching, then watches the game's window and moves it back onto the display if it landed elsewhere. The move is matched on the process ID the wrapper itself started, so a gamescope someone launched by hand is never touched.

A session also hands focus back when it ends. Focusing a streaming display leaves focus on an output that has no windows of its own, which strands input: nothing is focused, so no key or click reaches anything until something takes focus again. Each wrapper records the focused window before it starts and restores it on exit, falling back to the monitor that was focused if that window is gone by then.

The game runs nested inside **gamescope** at the display's exact geometry, with Proton's Wayland path switched off for the child. Both parts are needed. A Proton game under `PROTON_ENABLE_WAYLAND=1` is a native Wayland client that names its own output and picks whichever one satisfies the resolution it wants, so neither positioning the display nor moving a workspace moves the game.

No workspace on a streaming display is declared persistent, so the displays hold none of their own until a game runs.

Gamescope's own exit status is not usable: it segfaults on a natural shutdown regardless of how the game ended. Each wrapper runs the game through a small recorder that writes the game's real status where the wrapper can read it, so Steam's "game exited" handling still sees the truth.

A launch option runs in Steam's child environment, and that environment's `LD_LIBRARY_PATH` points at Steam's bundled runtime directories. Those hold libraries older than the ones Nix links against. The loader takes the first match by name, so a wrapper running its own tooling there dies at its first command: `mktemp` needs an `ATTR_1.3` symbol that Steam's 2019 `libattr` does not define. Both wrappers drop the inherited path for their own tooling and restore it for the game, which needs it to find the graphics drivers.

Gamescope also runs with `--keep-alive`, because a launcher that forks the game and exits would otherwise take the game down with it. And each wrapper re-asserts its display's mode on every tick of its poll loop, which is what repairs a reload mid-session.

Only one wrapper can run at a time. They share a lock because a single class-only rule cannot route two gamescope windows to two different displays; starting a second one prints which lock is held and exits.

Steam Remote Play hosting has to be enabled once, under Steam's Settings → Remote Play (`userdata/<id>/config/localconfig.vdf`, key `streaming_v2.EnableStreaming`). That file belongs to the Steam client and Nix must not own it, so this stays a UI toggle. Steam also needs its `-pipewire` flag under Wayland, which `steam.nix` sets by wrapping the package's `extraArgs`.

The portal needs a patch. In `xdg-desktop-portal-hyprland` 1.4.1, the out-of-buffers branch of the screencopy frame callback renegotiates the stream, which re-enters `PW_STREAM_STATE_STREAMING` synchronously and installs a fresh frame callback that the branch then destroys. A live stream is left that never receives another frame. Every retry also reallocates the buffer pool, so one late buffer costs a full renegotiation, Steam's capture size flaps, and its mmap on the freed pool fails with `EBADF`. Three upstream commits fix this, none in a release yet, so `assets/patches/xdph-screencopy-buffer-reuse.patch` back-ports all three and `portal.nix` applies them with an overlay.

HDR is unavailable: Steam Remote Play's HDR pass-through is documented for Windows hosts only, so both wrappers stay 8-bit SDR. The Deck OLED's panel is HDR-capable, but the limit is the host OS, not the client.

### Secrets

Secrets live under `./secrets/`, [sops-nix](https://github.com/Mic92/sops-nix)-encrypted and decrypted at activation using the host's age identity (`host.sshKey`). Most consumers read a secret *path* at runtime. A few need the value spliced into text that Nix builds at **evaluation** time, where a path is useless; those use `sops.templates` with `config.sops.placeholder.<name>`, which renders the file under `/run/secrets/rendered/`.

One template carries a **format contract worth knowing before you edit the secret**: `zen/allowed-cookies/<host>` is spliced into a JSON *value* position in Zen's `policies.json`, so it must decrypt to a **JSON array of origin strings**. Anything else produces invalid JSON, and Zen then discards every policy in the file, including the tracking-protection settings. An activation check warns when the rendered file breaks the contract, so a bad secret is noisy rather than silent.

## Directory layout

- `./flake.nix` — entry-point; auto-imports the `modules/` tree via `import-tree`.
- `./modules/flake/` — the assembly logic (`den.nix`, `options.nix`). Start here to understand the wiring.
- `./modules/base/` — the aspects `base` includes verbatim (`boot`, `secrets`, `nix`, `locale`, `network`, `audio`, `scheduling`, `shell`, `remotes`, `wireguard`, `wifi`).
- `./modules/users/` — per-user aspects, one file per user named after that user (`shochraos.nix`). Resolved by **name**, not through `includes`.
- `./modules/graphical/` — what `graphical` adds on top of `base`: Hyprland (`hyprland/`), the DankMaterialShell shell (`dankshell`), terminal, browser, editor, apps, mail, sync, kde-connect, printing, bluetooth.
- `./modules/features/` — aspects a host or sub-bundle selects directly rather than through `base`/`graphical`: the form factors `desktop` / `laptop`, `gaming/`, `ai`, `virtualization`, `media`, …. A file's folder names the layer that includes it, so moving an aspect between layers moves the file too.
- `./modules/hosts/<host>/` — `config.nix` (host overrides + `host.*` settings), `hardware.nix`, `filesystems.nix`.
- `./pkgs/<name>/package.nix` — packages nixpkgs does not carry, as ordinary `callPackage` expressions. These are **not** flake-parts modules, so `import-tree` ignores them; each is reached by a named overlay declared in the aspect that owns it (see `mp3tag`, `lgtv`, `gaming/packages`), which is also what keeps an unfree allowlist scoped to the aspect that needs it.
- `./lib/` — pure helper functions shared by aspects (`display.nix`, `audio.nix`). Also not flake-parts modules; `paths.nix` declares each under `helpers`, and both the aspects and the tests import them from there.
- `./tests/` — the `nix-unit` suites and the script behaviour checks that `nix flake check` runs.
- `./configs/` — raw config files for tools without a home-manager module.
- `./assets/` — icons, templates, shell scripts and patches referenced or installed by modules, plus the always-on rules for the oh-my-pi coding agent (`assets/omp/rules/`).
- `./secrets/` — [sops-nix](https://github.com/Mic92/sops-nix)-encrypted secrets.

## Testing

`nix flake check` runs six checks: `treefmt`, a unit suite, one behaviour check per shipped script, and a `pre-commit` check that runs the same two hooks a commit does.

Two of them also run at commit time. Entering the devshell installs a `pre-commit` hook — `cd` into the repo with direnv active, or `nix develop` once per clone — and after that `git commit` checks the staged files against treefmt and runs the unit suite before the commit is created. Both hooks run unconditionally, so a commit that stages nothing relevant still runs them. Nothing is rewritten: a formatting failure means the file needs `nix fmt`, and the commit is refused. `git commit --no-verify` bypasses both, and since hooks are per-clone and untracked, a fresh checkout has none until a devshell is entered there. CI is what enforces them.

The unit suite in `./tests/` covers logic a build cannot see. That is the display derivations in `./lib/display.nix` — which monitor rules get emitted, how workspaces bind to outputs, which screen the bar pins to, which output `hdr-set` targets, how a streaming mode is split into gamescope flags — plus the equalizer assertions in `./lib/audio.nix`, the `host.*` option contracts, and the argument guards on the `ai` functor. It finishes in about a fifth of a second.

The behaviour checks in `./tests/scripts/` run the shipped scripts — `hdr-set` with its `hdr` wrapper, `eq`, and the streaming wrappers — against a scratch `HOME` with `hyprctl` stubbed. For `hdr-set` they pin what a build cannot: `off` removes its line, `on` is idempotent, a failing `hyprctl` is tolerated, and the wrapper turns the setting off once the game window is gone while passing a child's exit status through. One case gets its own scenario because it is the bug the wrapper was rewritten for: a launcher process spawns the game and exits at once, and HDR must stay on until the window closes. For `eq` they pin that a selection is recorded before the handoff to systemd, and that a preset the filter does not have is refused. For the streaming wrappers they run the same assertions against both clients: each binds its own workspace and mode, both refuse to start while the other holds the lock, `ensure` costs read-only work on a healthy display but heals one after a reload, and the two generated wrappers are identical once their four data values and store hashes are masked, which is what keeps "one script, two clients" true rather than merely intended. The gamescope call gets its own assertions: it carries the display's geometry, the child gets Proton's Wayland path switched off, the workspace focus is dispatched rather than merely constructed, and the wrapper returns the game's exit status rather than gamescope's own crash. Two of the assertions cover placement and focus directly: a game window that appears on another monitor must be moved back onto the streaming display, a window already in the right place must be left alone, and the window that held focus before a session must have it again afterwards. The stub gamescope exits 139 like the real one and records what it was handed, so a wrapper that starts reporting success for a game that failed is caught here.

`hdr-set` and the streaming wrappers also share a case for the launch environment: with a directory of shadowing libraries on `LD_LIBRARY_PATH`, each wrapper must still run its own tooling and must hand the untouched value to the game. The case checks that the shadow still breaks a plain `mktemp` first, so a harness that quietly stopped reproducing the failure fails the check rather than passing it.

Two rules govern the suite. The logic under test lives in `./lib/`, so an aspect and its test call the same function instead of two copies of it. And a test that cannot fail gets deleted rather than kept: nothing here asserts a value the host build already forces, and `keepassxc-unlock` has no test because its wrapper puts its own `keepassxc` ahead of any stub on `PATH`, leaving nothing observable short of an eight-second delay.

## Common commands

Rebuilds go through [`nh`](https://github.com/nix-community/nh) (the Nix helper), which is wrapped in a few shell aliases. Each alias regenerates the matugen theme templates first (`theme-sync`), then targets the flake and the current host automatically:

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
# Formatting, shellcheck, the unit suite, the behaviour checks and the hooks
nix flake check

# Format the tree (nixfmt, shfmt, shellcheck)
nix fmt

# Update inputs manually
nix flake update                          # all
nix flake lock --update-input nixpkgs     # one
```

## License

[MIT](LICENSE) © 2026 Shochraos. The license covers the code in this repository; everything under `./secrets/` and any personal data is excluded.
