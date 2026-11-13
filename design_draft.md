# Desktop replica for GUI debugging

- **Author:** Shochraos
- **Status:** Draft; Technical Plan awaiting author decisions and approval
- **Date:** 2026-11-13
- **Target hosts:** Azazel and Solas; Seere and Sitri remain unchanged

## Overview

Provide a dedicated `agent` identity with mostly the same non-sensitive desktop configuration as the live personal account, for investigating desktop, DMS and graphical application bugs without operating the personal desktop. The replica must use the same application versions, Hyprland settings, DMS/Dux shell configuration, plugins, keybindings, theming, fonts and application preferences, except for documented credential, identity, privilege and headless-session differences.

The agent must be able to start the replica, reproduce GUI behavior, inspect screenshots and logs, experiment with its own desktop configuration and application state, and stop or reset the session. This is not a remote development environment. The role requires no project checkouts, project mounts or project-build workflow on either host. Repository editing and authorized builds remain in their existing environments outside this desktop role.

This is a design-only draft. The user has requested the technical plan for both hosts and retained destination-side SRT alongside separate agent accounts. It contains the goals, proposed access policy and technical architecture, including unresolved mechanisms and validation requirements. The final exhaustive implementation list follows the architectural decisions. No account creation, configuration implementation, build, activation or further computer-use session is authorized by this document.

The completed feasibility experiment supports a private headless Labwc parent running nested Hyprland. Both compositors reported NVIDIA hardware rendering. Native application display, screenshot capture, exact keyboard text and a pointer click were observed. The synthetic Qt Quick application required software rendering after EGL initialization failed. The final automated run exited nonzero when its final visual-review gate expired; its saved image was verified afterward. This is evidence for the core workflow, not general GPU-application compatibility or permissions under a new UID.

## The problem

The current desktop configuration combines the desktop behavior that must be replicated with personal credentials, privileges and startup integrations that must remain private. The required split is a shared desktop configuration plus personal-only identity and credential integrations, not a separate minimal desktop with a hand-picked subset of preferences. The exact merged result for a second Den/Home Manager user has not been evaluated.

The important existing owners are:

| Existing owner | Constraint on the eventual Nix changes |
| --- | --- |
| [Host composition](./modules/flake/den.nix), especially lines 21–70 and 83–90 | Both targets select the whole graphical profile and their own host features. Only `shochraos` is currently registered for Home Manager. Add the agent capability explicitly to Azazel and Solas, not to the server hosts. |
| [Personal account](./modules/users/shochraos.nix), lines 8–16 | Owns the existing SSH allow-list contribution, password-secret reference and `wheel` membership. Preserve these for the existing user; do not copy its account definition for the agent. |
| [Network](./modules/base/network.nix), lines 23–40 | Disables password/root SSH login and home-directory authorized keys. It also grants `networkmanager` to user recipients. The agent needs declarative SSH authorization without inheriting network-management authority. |
| [AI tools](./modules/features/ai/harness.nix), lines 3–8 and 44–55 | Grants the ydotool group and provides Hermes desktop configuration/autostart. Preserve relevant non-sensitive application configuration, but separate personal backend credentials, authenticated sessions and host-wide input authority. |
| [Base Home Manager defaults](./modules/base/config.nix), lines 18–50 | Mixes reusable CLI tooling with deployment helpers and an SSH-key-derived SOPS identity command. Separate software availability from permission to use credentials or deploy systems. |
| [Git](./modules/base/git.nix), lines 79–117, and [SSH](./modules/base/ssh.nix), lines 14–36 | Mix generic client setup with personal identity, secret-backed includes, private-key paths and a root-host alias. Share neutral client behavior, not those identities or authorizations. |
| [Browser](./modules/graphical/browser.nix), lines 148–163 and 178–281 | Includes personal policy ownership, browser startup and password-fed KeePassXC unlock. Replicate non-sensitive browser preferences and relevant startup behavior using independent application data, without personal vault access, cookies, logins or credential-fed unlock. |
| [Hyprland](./modules/graphical/hyprland/config.nix), lines 77–108 and 119–200, and [Duxshell](./modules/graphical/hyprland/duxshell.nix), lines 22–63 | Preserve the shared Hyprland and DMS/Dux desktop behavior. Adapt physical-output references and runtime paths for the headless session, separate greeter ownership, and identify any privileged or credential-dependent startup exceptions explicitly. Do not discard the shell, plugins or ordinary startup configuration as a sandboxing shortcut. |
| [Mounts](./modules/features/mounts.nix), lines 113–142 and 174–198 | NAS credentials and personal share access remain outside the replica. No project-share access is required for this role. Retain non-sensitive file-manager preferences where relevant, while recording unavailable personal mount targets as a reproduction difference. |

A separate UID and a sandboxed GUI launcher solve different problems. An ordinary SSH shell can still use whatever filesystem, device, IPC and network permissions the account possesses outside that launcher. A launcher allowlist is not an account-wide security boundary.

## Goals

1. Give the agent a dedicated, key-authenticated identity with its own private home, desktop runtime and application data. Preserve the existing personal account and its SSH access.
2. Share the same non-sensitive desktop configuration by default, including DMS/Dux, Hyprland, plugins, keybindings, themes, fonts, application packages and preferences. Keep one source of truth for shared settings rather than maintaining a separate reduced desktop fork. Exclude personal SSH configuration, keys, secrets and authenticated application state.
3. Provide an on-demand desktop that is independent of the personal Wayland session. Capture and native input must identify only the current agent session. Transport results through SSH; a public VNC or other remote-desktop listener is not required.
4. Provide a reproducible desktop baseline with independent writable home/config/cache/runtime state and a private session bus. Allow experiments and resets within the replica, and keep requested screenshots, logs and reproduction fixtures separately identifiable for cleanup or explicit retention. Do not seed it with personal application profiles or introduce project-source access.
5. Limit graphics access to an explicit host-specific render manifest. Azazel's prior test used `/dev/dri/renderD128`, `/dev/nvidia0` and `/dev/nvidiactl`; new-account access remains unverified. Solas requires independent AMD device discovery and validation. Device access is not authorization to change driver configuration, clocks, permissions or physical display state.
6. Start the configured desktop shell and the non-sensitive services needed to reproduce the live desktop, then launch the applications needed for the investigation. Review startup entries individually instead of disabling all autostart. Generate required theme state under the replica's account from the same non-sensitive inputs. Use rendering fallbacks explicitly; do not silently force software rendering and then claim to reproduce GPU behavior.
7. Bound resource use and session lifetime. Stop all owned descendants, verify shutdown, and remove disposable state. Keep failures and optional retained evidence distinguishable from successful cleanup.
8. Preserve personal configuration behavior and all hosts outside the approved rollout. Later verification must compare effective settings, group grants, secret ownership, services and activation outputs, not just check that the new user evaluates.

### Desktop fidelity

The default is the live desktop's non-sensitive configuration, not the minimal synthetic configuration used by the feasibility probe. DMS/Dux must actually run with its configured layout, styling and plugins; package installation alone is insufficient. Ordinary application preferences and safe startup behavior remain shared. Credentials, personal sessions and sensitive integrations are separated at their existing owners.

Headless output names, geometry, scale, runtime paths and service access can affect reproduction. Adapt them explicitly and record the differences. Necessary shared-system metadata or service interactions must be assessed by operation rather than removing whole desktop features without noting the loss of fidelity. This does not grant physical display control, host-wide input or system administration. A test depending on physical hardware or unavailable personal state must disclose that limitation.

### Proposed access policy

This table is a proposed permission budget, not a claim about currently enforced permissions. The technical plan must name the enforcement layer for each restriction and identify exceptions before activation.

| Resource or action | Proposed access |
| --- | --- |
| Replica home, desktop configuration and application data | Read/write to the replica's own writable settings and state for experiments. Its baseline comes from the shared non-sensitive configuration, not a copy of personal profiles. |
| Diagnostic artifacts and reproduction fixtures | Agent-owned screenshots, logs and non-sensitive sample files. No project repositories or project mounts are required. |
| Shared application packages, libraries, fonts and public Nix-store configuration | Read/execute. Installing a password manager or SSH client does not give the agent its credentials. Files already public-readable cannot be made secret by a GUI wrapper. |
| Non-sensitive desktop and application configuration | Shared by default, including DMS/Dux and Hyprland behavior. Use independent writable state and document each necessary difference from the live setup. |
| Screenshots, input and compositor IPC | Agent-session surfaces only, using that session's private sockets. No host-wide ydotool or physical input devices. |
| GPU | Only the verified interfaces needed for the test. Do not use broad device groups as a substitute for evaluating the resulting access. Account-wide device restrictions must also cover commands outside the GUI launcher if that guarantee is selected. |
| Logs and process inspection | Agent-owned processes and task logs. No blanket `systemd-journal`, `adm` or other broad log-reading grant. A specific sanitized host diagnostic can be supplied separately when needed. |
| Personal files, browser sessions, SSH/GPG agents, vaults and decrypted SOPS values | No access. Do not copy personal keys or secrets, change their owners to the agent, or add the agent as a SOPS recipient. Verify actual DAC/ACL and socket permissions before claiming account-wide denial. |
| Personal Wayland/X11 sockets, clipboard, PipeWire/audio devices, cameras and microphones | No access in the default test environment. Any required device or integration is a separate task-scoped grant. |
| Physical input, DRM card/modeset devices and VT/seat control | No access in the default test environment. Failure to start must not trigger a fallback into the personal session. |
| Shared system services and metadata | Identify the interactions required by the replicated desktop and their actual permissions. Expose only justified operations, record unavailable integrations, and keep administrative actions separate. A blanket bus allowance is not justified by wanting the same DMS configuration. |
| Administrative authority | No `wheel`, sudo rule, Docker/libvirt socket, NetworkManager-control grant, greeter access, trusted-Nix-user role, system activation or host service-management grant. Keep existing personal privileges unchanged. |
| Runtime packages and builds | Run the declaratively supplied desktop and application packages. This role requires no project builds on either host and grants no system-rebuild or activation authority. |
| Network | Support the network behavior needed by the replicated desktop and application cases. The egress policy remains undecided; offline-only operation is not a settled requirement. Any restriction that changes observed behavior must be recorded. A regular SSH shell retains ordinary host reachability unless separately restricted. |
| Personal SSH configuration, outbound credentials and forwarding | No access to the personal user's SSH configuration, private keys, SSH/GPG agents or host/Git credentials. The replica's incoming SSH authorization is configured independently. |

Home permissions, supplementary groups, device ACLs, generated wrappers, polkit rules and imported module defaults have not been verified on a new account. The existing source does not establish that every desired denial already holds.

## Non-goals

- Operating, capturing or attaching to the personal desktop or already-open personal application windows.
- Creating a reduced substitute desktop that omits ordinary non-sensitive configuration merely to simplify confinement.
- Copying personal credentials, SSH configuration, account identity, authenticated sessions or application data. Sharing the desktop configuration is a goal; cloning the personal home is not.
- Developing projects, granting project-directory access or adding a project-build workflow on either target host.
- Enabling the account on Seere or Sitri as an incidental effect of shared module changes.
- Granting general administration, changing host networking, exposing a remote-desktop port, or creating a new secrets distribution system.
- Proving arbitrary GPU applications, XWayland applications, physical audio/video devices or all desktop integrations work based on the synthetic probe.
- Treating a shared-kernel, shared-GPU sandbox as a VM-equivalent boundary against kernel or GPU-driver vulnerabilities.

## Open questions

SRT is retained in the design on both destination hosts. Its desktop integration is not implemented or validated. The Technical Plan records the remaining account-entrypoint, GPU-integration and private-service choices; none is resolved merely by installing SRT.

### Account-boundary alternatives

| Model | Mechanism and trade-off | Failure condition |
| --- | --- | --- |
| Regular unprivileged SSH account with a sandboxed GUI launcher | Normal shell access as `agent`, with a separately SRT-confined desktop tree. Supports ordinary host-side commands and file transfer within the account's Linux permissions. | Launcher restrictions do not cover the shell, host user services or other outside execution. This model cannot claim account-wide SRT confinement. |
| Confined SSH entrypoint for all agent commands | SSH enters an immutable controlled environment. Diagnostic shell execution, desktop control and artifact transfer occur inside the same confinement policy; unrestricted host troubleshooting is unavailable. | A forced command without startup-file, user-service, alternate-login and broker checks is bypassable. The complete mechanism requires implementation and validation. |

## Technical plan

### Scope and evidence

Enable the replica role explicitly on **Azazel and Solas**. Each host gets its own `agent` account, Home Manager profile and session state. It reproduces that host's non-sensitive desktop; Solas does not inherit Azazel's DMS bar, output geometry or NVIDIA environment. Seere and Sitri do not receive the role.

SRT runs on the destination host and remains part of the design. Its policy must cover the compositor, DMS, applications, diagnostic commands and their descendants. Sandboxing only a terminal while launching the GUI outside it does not meet this requirement.

The inspected root nixpkgs revision is `f4a03c008967841f2a0b3cb7c436fc6fc31671f6`. Its `sandbox-runtime` package is version **0.0.81**, so introducing an SRT flake input or moving the lock is unnecessary. A newer upstream revision was also inspected for comparison, not selected as an upgrade. Both versions' inspected Linux code creates a fresh `/dev`; neither supplies a supported GPU-mount setting. The package source and version-specific limitations are linked under Sources.

The existing Azazel experiment validates the custom-bubblewrap Labwc/Hyprland arrangement under the personal SSH UID, not SRT, a new account, full DMS or Solas. Solas has only been inspected through repository configuration in this drafting task. No live-host inspection or new experiment was performed.

### Process and trust boundaries

The following is the confined-entrypoint variant. The ordinary-SSH variant above preserves the same desktop process tree but cannot claim account-wide SRT confinement. Selection remains with the author.

```text
Hermes gateway
  |
  | SSH through the host's existing permitted interfaces
  v
Azazel OR Solas: dedicated agent UID
  |
  | immutable SSH entrypoint and explicit, immutable SRT settings
  | host-side supervision contains only trusted lifecycle/proxy code
  v
SRT Linux boundary, including the reviewed desktop integration
  |
  +-- private HOME, runtime directory, PID/network/IPC views and session bus
  +-- headless Labwc parent using only that host's approved render devices
  +-- nested Hyprland using that host's shared desktop configuration
  +-- DMS/Dux, private desktop services, applications and diagnostic shell
  +-- session-scoped capture/input helpers and exported evidence
```

The account separates ownership and application state. SRT supplies process-tree filesystem/network restrictions through its Linux bubblewrap backend. Trusted supervision owns lifecycle and resource limits. These mechanisms share a kernel and GPU driver with the live system; they do not establish VM isolation or zero shared-GPU impact.

The entrypoint, package, policy and any device adapter belong in immutable Nix-store outputs, referenced through root-managed configuration. None is loaded from agent-writable settings, a working directory, PATH lookup or a project checkout. The agent cannot change policy through command-line options or a writable control channel. A failed settings, namespace, device or dependency check stops startup; it never falls back to an unconfined shell or the personal compositor.

### Account and SSH delivery

Add `agent` only to the Azazel and Solas Den host registrations, with the existing `homeManager` class. Define its Linux account separately from `shochraos`: private home, distinct primary group, independent incoming public-key authorization and no personal password-secret reference. Inventory UID allocation before choosing numeric IDs; this is not permission to reuse an existing identity.

Do not grant `wheel`, NetworkManager control, greeter, ydotool, printer/scanner administration, realtime scheduling, trusted-Nix-user status or broad journal access. Render-device access must be explicit and bounded; installing the same application packages does not require sharing the personal account's privileges. Inspect supplementary groups contributed through both `extraGroups` and `users.groups.*.members`.

Preserve the existing SSH listener/firewall policy: Azazel currently exposes SSH on `en+`, whereas Solas permits it on its `home` and `home-split` WireGuard interfaces. Adding an account must not expose port 22 on additional interfaces or publish a desktop listener. Authorize only an owner-selected public key; no private key is copied into the replica.

For the confined variant, use a root-managed SSH Match rule and a dedicated immutable account entry shell. They must reject unsupported commands and start all agent-controlled execution inside SRT. Prevent agent-controlled shell startup files from running before SRT; disable user SSH rc files, user environment injection, SSH/GPG-agent forwarding, X11 forwarding, TCP/Unix-socket forwarding, tunnels and alternate unrestricted subsystem/file-transfer execution. Artifact transfer is part of the confined interface, not an SFTP exception. PTY and non-PTY requests must both traverse the entrypoint.

A forced command alone is insufficient. Prevent an unrestricted host user manager, lingering service, desktop/console login, cron/at job, D-Bus activation or other broker from executing agent-controlled code outside SRT. Home Manager activation remains owner-controlled and must not start the agent's desktop services in an ordinary host user manager. Verify effective PAM, SSH, display-manager and service behavior before describing this as account-wide confinement. Do not grant an arbitrary `systemd-run`, polkit or privileged command-execution interface as a shortcut.

### Reusing the desktop without inheriting personal authority

Keep the current host-selected application and desktop aspects as the common source. Separate personal identity, credentials and host-control grants at their existing owners before registering the second user. Do not copy the current personal home or replace the shared graphical profile with a reduced agent-only profile.

The required ownership split is:

| Configuration | Shared replica behavior | Personal-only behavior |
| --- | --- | --- |
| CLI, Git and SSH | Packages and neutral preferences | Personal Git identity/includes, host aliases and keys, forwarding, SOPS identity environment and deployment-specific authority |
| Hyprland | Settings, animations, window/layer rules, gestures and keybindings | Physical-seat/input authority and attachment to the live compositor |
| DMS/Dux | Shell package, styling, widget order, plugins, ordinary settings and private clipboard | Greeter ownership, credential-fed integrations and operations on the live host/session |
| Browser and KeePassXC | Versions, non-sensitive preferences, extensions/native messaging configuration and UI theme | Existing profiles, cookies, logins, personal vault path and automatic credential-fed unlock |
| Calendar, tasks and sync | Packages, UI settings and widgets; independent empty or non-sensitive fixture data | Personal CalDAV/HTTP accounts, URLs, passwords and live synchronization |
| Discord and other applications | Package versions and non-sensitive plugin/preferences configuration | Personal logins/data; absolute logging/cache paths must resolve under the recipient's home |
| Optional host features | Relevant application packages and preferences selected on that host | NAS credentials/mount access, backup credentials/jobs, SteamVR capability grants, private IRC/TV credentials and host-wide input |

Resolve the existing singleton hazards explicitly. `host.sshKey`, `host.flakeDir`, greeter `configHome`, system secret/template owners, backup notification ownership and the SteamVR helper must not change merely because Den traverses another user. Preserve their existing personal owners. No `agent`-derived SSH key or checkout becomes a host default. Do not clear merged secret/group settings with a broad agent override after the personal declarations have already been shared.

Use the existing personal-user aspect as the root of personal-only contributions and keep reusable settings at their present feature owners. Confirm the exact Den propagation with no-build evaluation before fixing the detailed implementation. This draft specifies the ownership contract, not an unevaluated Den helper API. Do not add host-level feature-enable booleans or duplicate the graphical include list for the agent.

The global Zen policy source is a special case: it is secret-backed and cannot be made safe merely by omitting the agent's Home Manager secret declaration. The replica must see a non-sensitive policy view at the same consumer path, while the personal host policy remains unchanged. Mask the personal runtime policy and supply the public policy inside the replica; never read its decrypted bytes to construct the replacement.

### Home, mutable settings and reset

Generate the agent baseline from its own non-sensitive Home Manager output. Treat the generated Nix-store baseline as immutable. For an investigation, materialize the mutable application configuration into a disposable run home and keep plugin/package links pointed at their immutable outputs. Home Manager's generated JSON symlinks are not writable just because their parent directory belongs to `agent`.

The run home is the only desktop HOME visible inside the session. HOME, XDG configuration/data/state/cache variables, temporary directories and runtime paths must agree on that identity. Never seed cookies, browser databases, SSH configuration, password databases, Nextcloud state, Hermes backend credentials or personal calendar files from `/home/shochraos`.

Use a unique run identifier and separate directories for writable desktop state and exported evidence. Persistent host-level account files are not the reset target. A reset stops the owned session, verifies its processes are gone and recreates only that run's disposable state from the baseline. Evidence is exported only when requested; default session cleanup removes disposable data. Explicitly retained evidence has a separate retention decision. Do not garbage-collect the Nix store or remove unrelated caches to claim cleanup.

Keep the policy and launcher outside both the mutable home and its writable ancestors. Sanitizing environment variables and working directory must happen before invoking SRT or any shell capable of reading user-controlled startup files. Preserve neutral Home Manager session variables only after removing personal credential, socket and deployment references.

### SRT integration work that cannot be represented as ordinary settings

Stock SRT is not yet sufficient for this desktop. These are required integration tasks, not verified capabilities:

1. **GPU devices:** SRT emits a fresh `/dev` after its filesystem mounts and skips `/dev/*` in the write allowlist. `filesystem.allowWrite` cannot expose a GPU. Add the approved device binds after the fresh `/dev`, preserving the rest of SRT's filesystem and network enforcement. An outer bubblewrap wrapper alone does not solve an inner SRT `/dev` that hides those devices again.
2. **Private desktop IPC:** Linux ignores the per-path `network.allowUnixSockets` setting. The session needs Unix sockets for Wayland, Hyprland, DMS and D-Bus. Enabling `allowAllUnixSockets` changes a global seccomp restriction; it is not a path allowlist. Before using it, hide host socket directories, keep the network namespace separate, expose only replica-owned pathname sockets and the required SRT proxy bridge, and independently prevent AF_VSOCK access. Mount visibility alone does not filter AF_VSOCK. Verify the actual helper/filter behavior of the selected package.
3. **Filesystem visibility:** SRT allows reads by default. Configure explicit read restrictions over personal homes, secret/runtime directories, host service sockets, mounts and other sensitive state, with only necessary package/font/driver/public-config and replica-state access. Read-only binding a socket does not make operations through it read-only. Resolve symlinks and verify the mounted result, not just the settings JSON. Account DAC/ACL remains a separate layer.
4. **Writable paths:** Allow only disposable replica state and the explicit evidence area. Verify SRT's automatic writable exceptions and mandatory denies against the generated paths. Keep private temporary paths inside the isolated view and prevent writable home content from becoming an outside startup hook.
5. **Nested application sandboxes:** Do not enable `enableWeakerNestedSandbox`, nested-user-namespace exceptions, Chromium `--no-sandbox` or a host-bus bypass to make an application launch. Browser/Electron sandbox compatibility is an explicit validation item. If the desired application cannot run under the selected boundary, report that conflict before changing the boundary.

Two GPU integration mechanisms remain open, without a default:

| Mechanism | Trade-off | Failure condition |
| --- | --- | --- |
| Package-scoped SRT source patch | Makes device handling explicit in the Linux backend and ships the change with the pinned package; requires maintaining and reviewing a security-sensitive patch across SRT updates. No global package override is required. | Patch no longer applies, generated code differs from reviewed source, or the new device path can widen filesystem/device access; startup must stop. |
| Immutable adapter selected through supported `bwrapPath` | Keeps SRT source unchanged and inserts a fixed host-owned device manifest at its bubblewrap boundary; argument rewriting is custom integration, not an upstream mount API. | Unknown argument layout, `--args`/descriptor encoding, missing or repeated `/dev` setup, or reordered safety arguments; reject rather than guess. |

Both mechanisms still require the filesystem/socket and lifecycle checks above. Running the GUI outside SRT, allowing the entire host `/dev`, or claiming path-scoped Linux Unix-socket filtering are not acceptable substitutes. The author must select the mechanism before the detailed implementation fixes its files and interfaces.

### Private services, launch behavior and desktop fidelity

All executable desktop services belong inside the SRT tree. The currently configured DMS systemd service, `uwsm-app` launch prefix and Hyprland shortcuts must not dispatch applications to an outside user manager. The same applies to D-Bus-activated portals, search, theme hooks, notifications and application helpers.

There are two defensible service-lifecycle designs. A private user-service manager inside the boundary could retain more native unit ordering, but requires proving its bus/cgroup setup, activation paths and compatibility with SRT. A direct supervisor could start the same DMS binary and required private services without an outside manager; it requires documented agent-only launch adaptations and does not reproduce UWSM/systemd-specific bugs. Neither is established by the earlier synthetic test. Keep both as author choices until the detailed implementation; do not quietly replace UWSM calls with unrestricted host service execution.

Start the actual configured DMS/Dux shell, Dux Files, search and required portal processes on the private bus. Preserve plugin/widget configuration. Calendar/task widgets use independent data; KDE Connect pairing, gamechat audio routing, physical output mirroring, host brightness, VPN/network modification and power actions remain unavailable unless a separate approved interaction can provide them safely. Keep their UI configuration where possible and report unavailable behavior instead of claiming full functional equivalence.

Use no personal PipeWire/PulseAudio or system-bus socket. If audio or portal reproduction requires it, provide private services and non-hardware test sources/sinks inside the boundary. A host system-bus proxy is a separate policy decision requiring a method-level service review; allowing all system D-Bus traffic to make DMS appear healthy is not permitted. Battery, temperatures and other host metadata may use justified read-only sources, but a read query must not also grant write/control authority.

Generate Matugen output in the run home from the same public theme inputs. Bootstrap the required generated Lua files from those inputs before Hyprland consumes them; DMS may refresh them after startup. DMS Lua imports for colors, outputs, cursor and layout must exist before use. Do not evaluate the Nix configuration against runtime-generated theme files or reuse a personal wallpaper/cache without classification. Record any substitute public input as a visual difference.

### Host adaptations

| Concern | Azazel | Solas |
| --- | --- | --- |
| Declared graphics | NVIDIA driver 620.70.06; retain the host's existing driver and package choices. | AMD graphics initialization through `amdgpu`; no NVIDIA environment or device nodes. |
| Candidate render access | Previously exercised `/dev/dri/renderD128`, `/dev/nvidia0`, `/dev/nvidiactl`. Recheck device identity and new-UID permissions before use. | Resolve the actual AMD render node and stable hardware identity during authorized preflight. No node number or new-UID permission has been verified. |
| Private compositor | Labwc with a headless output, hosting the same configured Hyprland. Check requested protocol versions rather than choosing an older parent by name. | Same intended topology, independently validated with Mesa/AMD drivers. The Azazel result is not a Solas PASS. |
| Driver discovery | Read-only driver libraries and required metadata; account for the tested NVIDIA EGL external-platform directory. | Read-only Mesa driver/library paths as actually supplied by this host; no copied NVIDIA workarounds. |
| Output model | Map HDMI-A-1 and DP-1 workspace assignments to named virtual outputs, preserving workspace order. Record loss of physical HDR/VRR/color behavior. | Map eDP-1 assignments and the configured 1.5 scale to a virtual output. Physical panel brightness, lid and touchpad behavior are not reproduced. |
| DMS | Preserve Azazel's bar/widgets and plugin preferences, including its NVIDIA telemetry selection. | Preserve Solas's battery widget, duxMirror plugin configuration and its own bar layout. Do not give mirror/power controls access to physical outputs or host suspend. |
| Resource envelope | Set a host-specific budget after checking memory/CPU headroom; sharing the GPU may still affect the live desktop. | Use a laptop-appropriate budget; do not inhibit host sleep, modify power profiles or keep a session lingering by default. |

A small initial virtual geometry may be useful for a smoke test, but it is not a faithful substitute for the host layout. Support explicit geometry/scale profiles for the bug being reproduced. The mapping must feed both Hyprland monitor/workspace generation and DMS screen/output settings, without changing global `host.outputs` for the personal desktop. Keep physical keybindings as shared configuration; unavailable hardware actions must fail without touching the live system.

No DRM card/modeset devices, physical input, uinput, seat/VT access, cameras or microphones are part of the default render manifest. Do not solve a new-UID startup failure by joining broad video/input groups or loosening global device modes. If an exact render-device ACL/group rule is necessary, document its UID scope and verify the actual resulting access before activation.

### Session control, evidence and cleanup

Provide conceptual operations for start, status, in-boundary command execution, capture, input, evidence export, stop and reset. These are a design contract, not commands currently installed on either host. In the confined variant, every operation enters through the same immutable boundary; unknown verbs and untrusted host-side command strings are rejected. Do not use shell `eval` on requests outside SRT.

Bind each run to host identity, UID, a random run ID, its supervisor/process identities and the actual private compositor sockets. Capture and input must fail if that identity cannot be confirmed. Never discover a session by taking the first Wayland socket or Hyprland instance. Keyboard and pointer injection use only private compositor protocols; pointer acceptance must include the persistent-connection behavior needed by the earlier test, not merely successful helper exit codes.

The supervisor starts the private parent, waits for its output/protocol readiness, starts Hyprland, checks private IPC/config errors, then starts the configured DMS and required services in dependency order. Do not rely solely on the previously failing Lua `--verify-config` path. Applications launch only after the desktop is ready. Preserve renderer logs; application software fallback is opt-in and makes a GPU-specific reproduction inconclusive.

Use a bounded process group/cgroup and explicit time, process, memory and CPU limits. GPU time and memory are not assumed to be isolated by those controls. The trusted lifecycle implementation must not expose general host command execution or cgroup-management authority to the workload. Concrete budgets remain deployment inputs, not invented host measurements.

Disconnect, timeout, startup failure and stop all trigger shutdown of the owned tree, including proxy bridges and private services. Kill only verified owned identities, verify that no descendants/namespaces remain, and then remove exact owned run directories without following symlinks into other paths. A failed cleanup leaves a reported residue, not a success marker. Export logs/screenshots through SSH without a public desktop port or an unrestricted file-transfer subsystem.

Permanent orchestration should use Bash and existing packaged tools. Do not turn the deleted temporary Python probe supervisor into repository tooling. If existing session-local input tools cannot satisfy persistent pointer behavior, specify and review that helper separately before implementation; the design does not assume an unobserved tool feature.

### Nix change map

This map identifies technical owners and candidate new artifacts. It is not the final exhaustive Detailed Implementation section: the entrypoint, SRT-device and private-service choices below must be resolved first. Existing paths describe the current dirty checkout; preserve concurrent work, including the untracked Discord and moved Duxshell files.

| Path | Planned responsibility |
| --- | --- |
| [modules/flake/den.nix](./modules/flake/den.nix) | Select the new capability and register `agent` on Azazel and Solas only. Keep common host/aspect composition here and server recipients unchanged. |
| `modules/users/agent.nix` (new) | Dedicated account, incoming authorization and role-specific profile integration; no personal password, key or privilege inheritance. |
| [modules/users/shochraos.nix](./modules/users/shochraos.nix) | Keep the existing personal account and provide the personal-only contribution root without changing its effective behavior. |
| `modules/features/agent-desktop.nix` (new) | One feature owner for immutable policy, selected SRT package/integration, lifecycle entrypoints, run-state handling, resource limits and safety assertions. Do not add an automatic features umbrella. |
| [modules/flake/paths.nix](./modules/flake/paths.nix) | Centralize any approved script/patch/source assets used by the feature. |
| [modules/flake/options.nix](./modules/flake/options.nix) and [modules/base/secrets.nix](./modules/base/secrets.nix) | Remove recipient-dependent ambiguity from personal host paths and SOPS identity ownership. Retain existing personal values; no new agent secret recipient. |
| [modules/base/config.nix](./modules/base/config.nix), [git.nix](./modules/base/git.nix), [ssh.nix](./modules/base/ssh.nix), [network.nix](./modules/base/network.nix) | Separate neutral defaults from personal credentials/deployment environment and network-control membership; add only scoped SSH enforcement. |
| [modules/graphical/hyprland/config.nix](./modules/graphical/hyprland/config.nix), [duxshell.nix](./modules/graphical/hyprland/duxshell.nix), [keybinds.nix](./modules/graphical/hyprland/keybinds.nix), [portal.nix](./modules/graphical/hyprland/portal.nix) | Keep shared desktop behavior; add recipient-local output/runtime/launch adaptations, separate greeter authority and keep portals/services within the private boundary. |
| [modules/graphical/browser.nix](./modules/graphical/browser.nix), [sync.nix](./modules/graphical/sync.nix), [editor.nix](./modules/graphical/editor.nix), [theming.nix](./modules/graphical/theming.nix), [discord.nix](./modules/graphical/discord.nix) | Preserve public application preferences while separating personal accounts, global secret-backed policy views and checkout assumptions; make writable/theme/log paths recipient-local. |
| [modules/features/ai/harness.nix](./modules/features/ai/harness.nix), [cpu-amd.nix](./modules/features/cpu-amd.nix), [modules/graphical/printing.nix](./modules/graphical/printing.nix) | Preserve packages and relevant preferences without automatically granting host-wide input, hardware control or printer/scanner memberships. Assess read-only power telemetry separately. |
| [modules/features/backup.nix](./modules/features/backup.nix), [mounts.nix](./modules/features/mounts.nix), [gaming/steam.nix](./modules/features/gaming/steam.nix), [irc.nix](./modules/features/irc.nix), [lgtv.nix](./modules/features/lgtv.nix) | Keep personal credentials, ownership and privileged helper recipients unchanged; share only the applicable non-sensitive application declarations. Do not add project mounts or backup privileges. |
| [modules/hosts/azazel/config.nix](./modules/hosts/azazel/config.nix) and [modules/hosts/solas/config.nix](./modules/hosts/solas/config.nix) | Host-specific render manifest, virtual output mapping and budgets, distinct from the live output/control declarations. No changes to hardware or filesystems are currently proposed. |
| `assets/scripts/agent-desktop-*.sh` (new, exact files depend on selected lifecycle) | Permanent Bash entry/session/control helpers only where native module/package behavior does not cover the contract. No standalone project-development service. |
| `assets/patches/srt-desktop-devices.patch` OR `assets/scripts/srt-desktop-bwrap.sh` (new, choice pending) | Selected package-scoped device integration. Do not create both by default. Any additional AF_VSOCK/filter integration must be listed explicitly in the detailed plan. |
| [README.md](./README.md), [AGENTS.md](./AGENTS.md), [WORKAROUNDS.md](./WORKAROUNDS.md) | During approved implementation only: add a broad architecture/usage description for the new role, correct guidance made inaccurate by multi-user support, and document any maintained SRT compatibility workaround at its existing documentation owner. No task-history inventory. |

The existing NVIDIA owner remains the source for Azazel's driver environment; it does not need modification merely to add a replica. Application-only owners without personal authority need no edits solely because they become shared. No flake input/lock, encrypted secret-value, server configuration, Git index or Git-history change is proposed by this design.

### Verification and rollout contract

Verification is staged; none of the runtime work below has been performed for this design.

1. **Source-only checks after implementation approval:** scoped Nix/Bash formatting and lint checks; verify the selected SRT integration against its exact source and emitted arguments, including missing-device and unknown-version rejection. Inspect the pinned package's seccomp helper rather than assuming packaging includes every upstream binary. No new test framework is required.
2. **No-build evaluation:** run through `ssh nix-workspace` as `agent` in `/projects/nixfiles`, using the locked environment, `--no-write-lock-file` and `--option allow-import-from-derivation false`. Use `nix flake check --no-build`; evaluate all four hosts. Include the explicit owner-managed source-inclusion step for new files; use an approved path-source fixture when untracked files are omitted by the normal Git-backed source, without staging them automatically.
3. **Preservation comparison:** capture before/after full host projections. Seere and Sitri should have equal toplevel derivations. Azazel and Solas should differ only by the approved role/composition changes; compare the personal user's effective Home Manager settings, secret/template owners, greeter path, SSH policy, group membership, system services, output mapping and capability helpers. Package paths and normalized non-sensitive agent preferences should match the same host's personal profile except for an explicit difference list. Compare data structure and paths, never decrypted values.
4. **Build gate:** separately authorize package/system builds through `nix-workspace`; a no-build evaluation does not prove the patched package or launcher works. No build is authorized by approval of this draft alone.
5. **Activation gate:** separately approve deployment on each host. Preserve ordinary personal SSH access and arrange an owner-controlled rollback path. Do not activate both hosts as a single assumed-safe operation. Stop sessions before changing their selected package/policy.
6. **Live acceptance per host:** obtain a new bounded test/computer-use approval identifying `azazel` or `solas`, verify the remote hostname, and perform the full configured DMS/Hyprland workflow. Test launch from the terminal shortcut and DMS launcher, ordinary GUI application display, exact keyboard input, pointer click, private clipboard, notification, theme generation and applicable private portal behavior. Record output scale/geometry and rendering backend; test a representative browser/Electron app without weakening its sandbox. No result on one host stands in for the other.
7. **Negative boundary checks:** use harmless owner-created fixtures, not actual secrets. Verify denied personal-home and host-runtime access, immutable policy/launcher, unavailable host buses/input/modeset devices, forwarding and alternate execution denial, direct-network denial and approved proxy egress, AF_VSOCK denial, and absence of outside-manager launch paths. Test symlink/path substitution and an invalid settings file. Test app-initiated helpers as well as direct shell commands.
8. **Cleanup and fidelity acceptance:** exercise normal stop, startup failure, disconnect and timeout; confirm owned processes, namespaces and sockets are gone and the personal compositor/session remains unchanged. Check reset restores the generated baseline. Keep the distinction between observed functional cases, automated harness exit status and visual verification; do not call an acknowledgment timeout a clean PASS.

If SRT integration or full DMS fails, stop at that layer and report the cause. Do not respond by granting physical input, the personal desktop socket, broad system D-Bus, unrestricted networking or host-level service execution. A required capability that conflicts with the boundary returns to the author as a design decision.

### Decisions and inputs still open

The user has selected two target hosts, separate accounts, a mostly identical non-sensitive desktop and destination-side SRT. These are settled requirements. The following mechanisms are not yet selected or validated:

- Account boundary: ordinary SSH with a confined desktop process tree, or an enforced entrypoint covering all agent command execution. Only the latter may claim account-wide confinement, after bypass checks.
- SRT device integration: package-scoped source patch or immutable `bwrapPath` adapter, with the failure conditions described above.
- Desktop-service lifecycle: private in-boundary user manager or direct in-boundary supervision, with any UWSM/systemd fidelity limitation recorded.
- Actual host render-device identity/permissions, account UID allocation, selected incoming public key, resource budgets and evidence retention.
- Required egress destinations and application proxy compatibility. Offline-only operation is not selected. Do not deploy an empty network allowlist and then describe network-dependent application behavior as reproduced.
- Any required host-service interaction that cannot be supplied privately, and the bug cases used to judge fidelity.

This technical section is ready for author review, not implementation. Alternatives, the final exhaustive implementation list and formal design review remain later stages.

### Sources

- [Locked nixpkgs SRT recipe, version 0.0.81](https://raw.githubusercontent.com/NixOS/nixpkgs/f4a03c008967841f2a0b3cb7c436fc6fc31671f6/pkgs/by-name/sa/sandbox-runtime/package.nix).
- [SRT 0.0.81 Linux backend](https://raw.githubusercontent.com/anthropics/sandbox-runtime/v0.0.81/src/sandbox/linux-sandbox-utils.ts) and [configuration schema](https://raw.githubusercontent.com/anthropics/sandbox-runtime/v0.0.81/src/sandbox/sandbox-config.ts): fresh device filesystem, Unix-socket restrictions, binary overrides and nested-namespace caveats.
- [SRT 0.0.81 documentation](https://raw.githubusercontent.com/anthropics/sandbox-runtime/v0.0.81/README.md): filesystem defaults, proxy networking and security limitations.
- [Compared upstream Linux backend at 0bbebed0aa9a8e628dc4df8bc30293550a1988eb](https://raw.githubusercontent.com/anthropics/sandbox-runtime/0bbebed0aa9a8e628dc4df8bc30293550a1988eb/src/sandbox/linux-sandbox-utils.ts) and [schema](https://raw.githubusercontent.com/anthropics/sandbox-runtime/0bbebed0aa9a8e628dc4df8bc30293550a1988eb/src/sandbox/sandbox-config.ts); comparison does not authorize an upgrade.
- [Locked DMS Home Manager module](https://raw.githubusercontent.com/AvengeMedia/DankMaterialShell/43255a46ea01e9d0de1fe8ce9897c0d71566b2a8/distro/nix/home.nix): generated settings/plugin links and systemd-based launch behavior.

*Drafted with EGM*
