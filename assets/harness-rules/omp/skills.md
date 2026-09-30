---
description: >-
  Cross-cutting skill routing (docs, review, planning, skills authoring, web
  fetching). Read rule://skills at task start; language packs load
  automatically via the lang-* TTSR rules. A Cloudflare-blocked fetch is
  never skipped — it routes through skill://cloudflare-bypass.
---
Cross-cutting skill routing. Language packs load automatically through the
`lang-*` TTSR rules; the tasks below need a deliberate skill pick:

- Writing or restructuring user-facing docs, proposals or specs:
  `skill://doc-coauthoring`.
- Creating or updating a skill (manage_skill): read `skill://writing-skills` first.
- The user asks for a capability that might exist as an installable skill:
  `skill://find-skills`.
- Feature-sized change complete, before reporting: `skill://requesting-code-review`.
- The user gives review feedback: `skill://receiving-code-review` before
  implementing suggestions.
- Executing an existing `.omp/<TOPIC>-PLAN.md`: `skill://executing-plans`.
- Independent parallelizable slices: `skill://dispatching-parallel-agents`.
- Feature or bugfix in a language with a test runner: `skill://test-driven-development`.
- Diagnosing a defect: `skill://systematic-debugging`.

Self-written pack — the ten managed skills, also auto-nudged by the `lang-*`
rules where noted:

- A repository moved to a new absolute path: `skill://omp-project-migration`
  (migrate memory bank, sessions and history before resuming there).
- Unattributed Nix eval/build warnings: `skill://tracing-nix-eval-warnings`
  (also nudged by `lang-nix`).
- Changes to this config's omp wiring (`assets/harness-rules/omp/`, `modules/features/ai/`,
  skills packaging): `skill://omp-rule-and-skill-probe` (also nudged by `lang-nix`).
- Bash driving pactl or PipeWire: `skill://pactl-bash-daemon` (also nudged by
  `lang-shell`).
- DankMaterialShell plugin changes: `skill://verifying-dms-plugin-changes`.
- A Steam game, non-Steam shortcut or launch-option wrapper (`PROTON_*`, hdr,
  gamescope, mangohud, gamemoderun, a shell script) dies instantly with exit 127
  or exit 1, or fails only under the launch option while working from a
  terminal: `skill://steam-launch-env-diagnosis` (the launch child's scrubbed
  library path, steam-runtime shadowing, and the `$ORIGIN` fix).
- End of a coding task: `skill://end-of-task-memory-update` alongside the
  retain/learn write.
- A fetch via `read`, `browser` or `web_search` hits a Cloudflare challenge,
  403/503 or any anti-bot wall — or returns an empty/stub shell (JS SPA): read
  `skill://cloudflare-bypass` and route the fetch through the Scrapling MCP
  server. Normal omp searching still happens; when a result comes back
  blocked, follow up by fetching that URL through the skill, never dropping it.
- Measuring per-netns kernel FIB events or routing convergence in netns or
  Mininet labs: `skill://kernel-route-monitor-measurement`.
- Adding or debugging a `nix-unit` suite — in a flake-parts repo or inside a
  derivation: `skill://nix-unit-in-flake` (wiring, the path/interpolation
  traps, `expectedError` matching, and which contracts are worth testing).
