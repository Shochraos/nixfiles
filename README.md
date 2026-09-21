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

`host.streaming.displays` declares one entry per streaming client. Each entry generates two commands: a `<name>-display` helper that owns the output name and mode, and a `<name>` launch-option wrapper that runs the game. Azazel declares `frame` (2560x1440@120) and `deck` (1280x720@90). Put the wrapper in a shortcut's launch options in place of `%command%`:

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

### SteamVR

SteamVR raises thread priority with `sched_setscheduler`, and the kernel authorizes that through `RLIMIT_RTPRIO` rather than through a capability. A capability is unreachable from inside Steam anyway, so `steam.nix` grants the limit instead: `rtprio 95` for the user, applied by `pam_limits` at login, because it has to be in place before Steam starts. Azazel only, alongside the rest of the gaming aspect.

Two independent causes make the capability unreachable. `bubblewrap` sets `PR_SET_NO_NEW_PRIVS` unconditionally, and the kernel answers by intersecting any file-granted capability away at exec, so `setcap` on anything Steam launches is inert. Entering a user namespace is the second cause: it drops whatever capabilities the process held in the initial namespace. Real-time priority and the high-priority Vulkan queue are both checks against that namespace, so neither can be satisfied from inside the sandbox.

Setting `cap_sys_nice=p` on `vrcompositor-launcher` still silences SteamVR's setup prompt, because that prompt is a `getcap` check and nothing more. `steam.nix` applies the capability at boot with a oneshot unit; re-run it by hand with `systemctl start steamvr-cap-sys-nice`. Use `=p`, not the `=eip` form that `vrsetup.sh` and every forum post prescribe. The `e` bit sets the file's effective flag, which triggers secure-execution mode even though the capability itself is stripped; the loader then ignores `LD_LIBRARY_PATH` and cannot find `libcap.so.2`. No default library path on this host provides it. A SteamVR update replaces the binary and clears the capability again, so the prompt returns until the next boot or a manual re-run.

Asynchronous reprojection therefore stays off. It needs a high-priority Vulkan queue, whose capability check is the initial-namespace one, so the login limit cannot help it. `enableLinuxVulkanAsync` also ships `false` and would need setting even with a working capability.

`useFacetRenderer` is not in SteamVR's shipped defaults, and NVIDIA users report it helps. A home-manager activation step merges `steamvr.useFacetRenderer = true` into `~/.local/share/Steam/config/steamvr.vrsettings`. Nix edits that file in place; it must not own it, because SteamVR keeps its own `installID` and version-notice state there. Once the key is set the step does nothing. It also does nothing until SteamVR has run once and created the file.

### Herdr

`modules/graphical/terminal.nix` declares Herdr's configuration through home-manager's `programs.herdr`, which renders `settings` to `$XDG_CONFIG_HOME/herdr/config.toml` and reloads a running server whenever the file changes.

The package comes from nixpkgs, so shell completions and Herdr's agent skill file arrive with it, and updates ride the normal nixpkgs bump. A flake input tracking upstream releases was tried and removed. It builds from source, so it is absent from the binary cache, and it ships the bare binary without those two extras.

That config is a store path, so Herdr's settings UI cannot write to it. Sidebar geometry and session state live in `~/.config/herdr/session.json` and `$XDG_STATE_HOME/herdr/`, and both stay writable. Change theme, sound, notifications, or sidebar rows here instead, and the reload hook applies them to a running server.

`xdg.configFile."herdr/config.toml".force = true` is load-bearing. Herdr writes that file itself on first run, and home-manager refuses to replace a regular file it does not own, which aborts the whole activation.

Two settings are deliberate. `terminal.shell_mode = "login"` makes pane shells source `~/.profile`, the source of `PI_CONFIG_FILES` and `NH_FLAKE`; a session started without those two would otherwise hand panes an environment missing both. `update.version_check = false` disables a background version check that can never succeed: Herdr detects a `/nix/store` executable path and refuses to self-update.

Notification delivery uses Herdr's `system` backend, which shells out to `notify-send`, so the aspect installs `libnotify`. Herdr treats a missing `notify-send` as a silent no-op, not an error.

One Herdr client starts with the session. An `hl.on("hyprland.start", …)` hook in the same aspect runs `hl.exec_cmd("ghostty -e herdr", { workspace = "2" })`, so the compositor opens it on workspace 2 and it does not reappear on `hyprctl reload`.

The second argument is a **per-exec rule**, not a window rule. Hyprland attaches it to that spawned process alone, matched through the `HL_EXEC_RULE_TOKEN` the child inherits, and unregisters it as soon as one window matches. Terminals you open later are untouched, and nothing is left in `window_rule` to match `ghostty` as a class.

### Hermes

`modules/features/ai/harness.nix` declares [Hermes Agent](https://github.com/NousResearch/hermes-agent), Nous Research's general-purpose agent, in the same block that owns oh-my-pi. The intent is a second agent for work that writes no code: same provider, same model, and only the parts of the oh-my-pi setup that are not coding.

The flake input is pinned to the release tag `v2026.9.14` instead of tracking `main`, because upstream documents its flake and modules as Tier 2 and warns that commits to `main` may break them. The cost of the pin is that a version bump is a manual edit plus `nix flake lock`.

The package is the `minimal` variant with no extra dependency groups. Every provider-specific extra (TTS, voice, cloud sandboxes, messaging adapters, external memory backends) is a lazy `pip install`, which cannot write to a read-only `/nix/store`, so taking those groups would buy dead weight. Web search and extract need neither a group nor an API key: with no credential configured, dispatch rotates the vendors' anonymous free tiers, and a keyed backend that fails retries on that ring once.

One secret carries the whole credential story. `commandcode/api-key` is rendered into `hermes.env` and merged into `~/.hermes/.env` at activation, and the model is `commandcode/Qwen/Qwen3.8-Omni-Flash`, on the same provider oh-my-pi uses. CommandCode's own metadata calls that model non-reasoning, which is wrong on the wire: probe sessions recorded 53 reasoning tokens for a one-line puzzle. It also changes nothing for Hermes, which gates its reasoning parameters to OpenRouter and the few hosts it names explicitly, so none are ever sent to this provider.

Rules live in `assets/harness-rules/hermes/SOUL.md` and install to `~/.hermes/SOUL.md`. That file is the only rules channel Hermes injects from anywhere: the other context files it reads (`AGENTS.md`, `.hermes.md`, `.cursorrules`) are discovered per working directory, one per session, and the first match wins, while its own built-in guidance already covers tool discipline, memory and finishing the job. So the file carries the house layer — how to report work, a routing line for every installed skill, where a new skill is written, the prose audit, and a short `Never` block covering secrets, unrequested commits, other people's work, destructive actions and unverified claims. The routing lines exist because Hermes' own index carries only each skill's name and description, never its "when to use" section. The language packs, the repository bootstrap, and the plan-file conventions stayed with oh-my-pi.

Skills come from `agent-skills-nix`, reached through two entries of `skills.external_dirs`. The first is a selection of 25 explicit names, joined by `mkSkillset`: `vendored-avoid-ai-writing`, `shared-cloudflare-bypass`, `hermes-latex-writing` (vendored from `dbosk/claude-skills`), and 22 slices of Hermes' own catalogue (`hermes-pdf`, `hermes-p5js`, `hermes-arxiv`, and so on) that the skills repository packages from the `hermes-agent` source tree. Each slice is its own derivation, so nothing pulls a whole payload into the closure, and a store path is read-only, which stops the agent rewriting a procedure it is meant to follow. `mkSkillset` rejects a name it does not have at evaluation time, so an upstream rename is an eval error naming the available skills rather than a silently smaller set. The Scrapling MCP server that `cloudflare-bypass` calls is registered for Hermes as well, reusing the same `scrapling-runtime` package oh-my-pi points at. The second entry is the whole `hermes-managed-skills` payload from the same repository, which ships the skills Hermes has written, and grows without any further change here.

New and updated skills are written elsewhere. `skills.create_dir` points at `skills/hermes-managed/` in the `agent-skills-nix` checkout, so `skill_manage` drops the directory into the tree the payload is built from instead of a git-less `~/.hermes/skills/`. Hermes searches that directory before the payloads, so a skill it has just written is readable immediately, while the payload catches up on the next rebuild.

The selection exists because Hermes never seeds its own catalogue on a Nix install. The package ships 58 skills under `share/hermes-agent/skills`, but the index only carries skills that exist as files, so a fresh `~/.hermes` lists the selection above and nothing else. `hermes skills opt-in --sync` is the other way to fill that gap, and it copies all 58 into `~/.hermes/skills` as read-only store copies, including the 12 coding skills and the 4 macOS-only ones.

Three settings are deliberate. `agent.coding_context = "off"` stops Hermes from adding a coding brief and a git snapshot whenever the working directory looks like a checkout. `updates.check = false` mirrors the oh-my-pi setting for the same reason: a Nix install cannot update itself, so the passive GitHub check is pure traffic. `browser.backend = "off"` picks the built-in browser tools outright and silences the once-a-day notice Hermes prints when the optional Browser Use CLI is missing, whose installer writes into `$HERMES_HOME` rather than here.

`~/.hermes/config.yaml` is the exception to this repository's read-only-config habit. Activation regenerates it from `settings`, and Hermes merges rather than replaces, so Nix keys win while keys it wrote itself survive. The CLI refuses `hermes config set` and `hermes config edit` while the generated `.managed` marker exists, which makes the module the file to edit, not the config.

### Secrets

Secrets live under `./secrets/`, [sops-nix](https://github.com/Mic92/sops-nix)-encrypted and decrypted at activation using the host's age identity (`host.sshKey`). Most consumers read a secret *path* at runtime. A few need the value spliced into text that Nix builds at **evaluation** time, where a path is useless; those use `sops.templates` with `config.sops.placeholder.<name>`, which renders the file under `/run/secrets/rendered/`.

One template carries a **format contract worth knowing before you edit the secret**: `zen/allowed-cookies/<host>` is spliced into a JSON *value* position in Zen's `policies.json`, so it must decrypt to a **JSON array of origin strings**. Anything else produces invalid JSON, and Zen then discards every policy in the file, including the tracking-protection settings. An activation check warns when the rendered file breaks the contract, so a bad secret is noisy rather than silent.

### Backups

`modules/features/backup.nix` declares one borg job, and the host supplies only data: `host.backup.repo` plus the `paths` and `excludes` lists in `modules/hosts/azazel/config.nix`. Azazel backs up `/mnt/nextcloud/Security`, the KeePass vault and the Aegis exports, to a Hetzner Storage Box every day at 03:30, keeping seven daily, four weekly and six monthly archives. `prune` and `compact` run after every create, the job runs as root, and the timer is persistent, so a run missed while the machine was off happens at the next boot.

The box's hostname and account name are sops secrets, so the store carries only an alias. The repository is `ssh://storagebox/./security`, and `BORG_RSH` points borg at the ssh config that sops renders to `/run/secrets/rendered/backup-storagebox-ssh`. The repository is encrypted with `repokey`, whose key sits inside the repository wrapped by a passphrase from sops. The mode matters: the passphrase alone restores the archives, where `keyfile` keeps the only key on the machine being backed up. The box stores blobs it cannot itself read.

Nextcloud already syncs that directory, and borg adds dated archives held by a second provider, so a mistake on the Nextcloud side, or the loss of that account, does not take the last remaining version with it.

Restoring needs no `sudo`. All four secrets render `owner = shochraos`, and home-manager exports `BORG_REPO`, `BORG_RSH`, `BORG_REMOTE_PATH` and `BORG_PASSCOMMAND` from the same two rendered files the job reads.

Two commands wrap the usual round trip. `backup mount` mounts the newest archive at `$XDG_RUNTIME_DIR/borg/<archive>`, prints that path and lists the archived root; pass an archive name to mount a different night, and it reports the existing mount instead of stacking a second one over it. `backup unmount` unmounts everything under that directory and removes the mountpoints, naming any mount a running process is holding open. Both come from the backup aspect, which also carries the host's source paths and repository.

```bash
borg list                                         # every archive
borg list --short --last 1                        # the newest
borg list --short --glob-archives 'Azazel-backup-2026-09-18*'
borg list ::<archive>                             # the paths inside one archive
borg extract --stdout ::<archive> mnt/nextcloud/Security/KeePass/Vault.kdbx > /tmp/Vault.kdbx
borg diff ::<archive1> ::<archive2>               # what changed between two nights
```

An archive stores absolute paths without the leading slash, so `/mnt/nextcloud/Security/…` comes back as `mnt/nextcloud/Security/…`. `borg mount` is available for browsing instead of extracting.

Two of those secrets are the disaster path: the repository passphrase, and the age key `~/.ssh/azazel` that decrypts `secrets/secrets.yaml` at all. A copy of both outside Azazel is the difference between a backup and a pile of unreadable blobs. The box password is a third thing, and its only use is rotating or revoking the SSH key. The Hetzner console cannot change that key once the box exists.

A failed run is visible in `systemctl --failed` and `journalctl -u borgbackup-job-backup`. Nothing notifies yet.

### Wallets

`modules/features/crypto.nix` installs `electrum` and `feather` on Azazel, and runs a system Tor for them. `services.tor.enable` alone starts a daemon with no SOCKS port, so the aspect also sets `client.enable` and pins `socksListenAddress.port` to 9050. That address is where Feather's compiled defaults already point.

Feather ships its own Tor and unpacks a copy into `~/.config/feather/tor/` on first use. Those copies keep absolute `/nix/store` interpreter and RUNPATH entries, so after a nixpkgs bump and a garbage collection the libraries they name are gone and the bundled Tor can never start again. Feather cannot repair that itself: it reads the installed version by running that same binary, and its re-copy refuses to overwrite an existing file. So the `feather` on `PATH` is a wrapper that adds `--use-local-tor`. Feather then uses the 9050 daemon instead of unpacking one, and records that choice in its own settings on first launch.

Litecoin is not covered. `electrum-ltc` is the only LTC wallet nixpkgs carries, and it cannot start on this revision. Its `electrum_ltc/util.py` calls the `asyncio.get_event_loop()` that Python 3.14 removed, and three hardware-wallet plugin dependencies pull `python-ecdsa`, which nixpkgs marks insecure (CVE-2024-23342). Upstream's last commit was in November 2022, so this needs a port rather than a version bump.

## Directory layout

- `./flake.nix` — entry-point; auto-imports the `modules/` tree via `import-tree`.
- `./modules/flake/` — the assembly logic (`den.nix`, `options.nix`). Start here to understand the wiring.
- `./modules/base/` — the aspects `base` includes verbatim (`boot`, `secrets`, `nix`, `locale`, `network`, `audio`, `scheduling`, `shell`, `remotes`, `wireguard`, `wifi`).
- `./modules/users/` — per-user aspects, one file per user named after that user (`shochraos.nix`). Resolved by **name**, not through `includes`.
- `./modules/graphical/` — what `graphical` adds on top of `base`: Hyprland (`hyprland/`), the DankMaterialShell shell (`dankshell`), terminal, browser, editor, apps, mail, sync, kde-connect, printing, bluetooth.
- `./modules/features/` — aspects a host or sub-bundle selects directly rather than through `base`/`graphical`: the form factors `desktop` / `laptop`, `gaming/`, `ai` (both agents), `virtualization`, `media`, `crypto`, …. A file's folder names the layer that includes it, so moving an aspect between layers moves the file too.
- `./modules/hosts/<host>/` — `config.nix` (host overrides + `host.*` settings), `hardware.nix`, `filesystems.nix`.
- `./pkgs/<name>/package.nix` — packages nixpkgs does not carry, as ordinary `callPackage` expressions. These are **not** flake-parts modules, so `import-tree` ignores them; each is reached by a named overlay declared in the aspect that owns it (see `mp3tag`, `lgtv`, `gaming/packages`), which is also what keeps an unfree allowlist scoped to the aspect that needs it.
- `./tests/` — the `nix-unit` suites and the script behaviour checks that `nix flake check` runs. Each suite calls an aspect's own lambda with hand-made entity arguments and asserts on what it returns, so an aspect and its test share no helper layer that could drift from the code under test.
- `./configs/` — raw config files for tools without a home-manager module.
- `./assets/` — icons, templates, shell scripts and patches referenced or installed by modules, plus the always-on rules for the two agents (`harness-rules/omp/` for oh-my-pi, `harness-rules/hermes/SOUL.md` for Hermes Agent).
- `./secrets/` — [sops-nix](https://github.com/Mic92/sops-nix)-encrypted secrets.

## Testing

`nix flake check` runs eight checks: `treefmt`, a unit suite, one behaviour check per shipped script, a check over the Hermes rules, and a `pre-commit` check that runs the same two hooks a commit does.

Two of them also run at commit time. Entering the devshell installs a `pre-commit` hook — `cd` into the repo with direnv active, or `nix develop` once per clone — and after that `git commit` checks the staged files against treefmt and runs the unit suite before the commit is created. Both hooks run unconditionally, so a commit that stages nothing relevant still runs them. Nothing is rewritten: a formatting failure means the file needs `nix fmt`, and the commit is refused. `git commit --no-verify` bypasses both, and since hooks are per-clone and untracked, a fresh checkout has none until a devshell is entered there. CI is what enforces them.

The unit suite in `./tests/` covers logic a build cannot see. Each case calls an aspect's own lambda with hand-made entity arguments and asserts on what comes back — which monitor rules get emitted, how workspaces bind to outputs, which screen the bar pins to, how a streaming mode reaches gamescope, which hooks the display script registers. Two cases cannot read a value at all and force a derivation path instead: a display mode that fails to parse, and an `hdr` table with the wrong number of entries. The rest cover the equalizer assertions the `audio` aspect publishes, the `host.*` option contracts, and the argument guards on the `ai` functor. It finishes in about a fifth of a second.

The behaviour checks in `./tests/scripts/` run the shipped scripts — `hdr-set` with its `hdr` wrapper, `eq`, the streaming wrappers, and `backup` — against a scratch `HOME` with the external commands stubbed: `hyprctl` for the first two, and `borg` plus `findmnt` for `backup`, which is why neither tool is pinned in that wrapper's `runtimeInputs` (a `writeShellApplication` puts its own `runtimeInputs` ahead of `PATH`, so a pinned tool cannot be stubbed). For `hdr-set` they pin what a build cannot: it targets the host's single `hdr = true` output, `off` removes its line, `on` is idempotent, a failing `hyprctl` is tolerated, and the wrapper turns the setting off once the game window is gone while passing a child's exit status through. One case gets its own scenario because it is the bug the wrapper was rewritten for: a launcher process spawns the game and exits at once, and HDR must stay on until the window closes. For `eq` they pin that a selection is recorded before the handoff to systemd, and that a preset the filter does not have is refused. For the streaming wrappers they run the same assertions against both clients: each binds its own workspace and mode, both refuse to start while the other holds the lock, `ensure` costs read-only work on a healthy display but heals one after a reload, and the two generated wrappers are identical once their four data values and store hashes are masked, which is what keeps "one script, two clients" true rather than merely intended. The gamescope call gets its own assertions: it carries the display's geometry, the child gets Proton's Wayland path switched off, the workspace focus is dispatched rather than merely constructed, and the wrapper returns the game's exit status rather than gamescope's own crash. Two of the assertions cover placement and focus directly: a game window that appears on another monitor must be moved back onto the streaming display, a window already in the right place must be left alone, and the window that held focus before a session must have it again afterwards. The stub gamescope exits 139 like the real one and records what it was handed, so a wrapper that starts reporting success for a game that failed is caught here. For `backup` the check pins the round trip: an explicit archive name is honoured, a second mount reports the existing mount instead of re-mounting, unmount clears every mount it started and removes the mountpoints, a busy mount is named on stderr and returns non-zero rather than being quietly dropped, and an unknown verb prints usage. Its stub `borg` and `findmnt` keep the mounted set in a directory, and the stub drops its fake tree on unmount so the wrapper's cleanup runs against the empty mountpoint a real FUSE unmount leaves behind. The check also proves the stub is the `borg` on `PATH`, so a harness that stopped substituting would fail rather than pass.

`hdr-set` and the streaming wrappers also share a case for the launch environment: with a directory of shadowing libraries on `LD_LIBRARY_PATH`, each wrapper must still run its own tooling and must hand the untouched value to the game. The case checks that the shadow still breaks a plain `mktemp` first, so a harness that quietly stopped reproducing the failure fails the check rather than passing it.

The rules check reads `assets/harness-rules/hermes/SOUL.md` together with the skill directories Hermes actually loads, and compares the two in both directions: a routing line naming a skill that no payload provides fails the build, and so does a skill with no routing line. It takes each bullet's trailing backticked token as the skill name, which is why the list is written that way.

Two rules govern the suite. A test calls the aspect itself rather than a copy of its logic, so a case goes red when the aspect stops consuming the value it asserts on. Reading deep paths out of what the aspect returns is what carries that through a functor aspect or a home-manager half. And a test that cannot fail gets deleted rather than kept: nothing here asserts a value the host build already forces, and `keepassxc-unlock` has no test because its wrapper puts its own `keepassxc` ahead of any stub on `PATH`, leaving nothing observable short of an eight-second delay.

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
