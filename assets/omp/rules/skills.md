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
  After the write, present the finished SKILL.md to the user and ask whether it
  should be promoted into the nix-skills repo as a new `managed-skills` package
  (alongside `superpowers-skills` and `vendored-skills`). If the user confirms,
  add it there and — once the payload is live — delete the managed copy
  (`manage_skill` delete): the nix payload then delivers it, and a second copy
  in `~/.omp/agent/managed-skills/` would be redundant. Until promotion a
  managed skill is backed by no git history.
- A skill added to nix-skills that no `lang-*` rule auto-nudges (those fire
  on file-type edits, so they cover only language skills) needs a trigger
  bullet in this file's routing list in the same change — this rulebook is
  nixfiles' routing index, and an unindexed nix-skills skill is discoverable
  by description alone.
- The user asks for a capability that might exist as an installable skill:
  `skill://find-skills`.
- Feature-sized change complete, before reporting: `skill://requesting-code-review`.
- The user gives review feedback: `skill://receiving-code-review` before
  implementing suggestions.
- Executing an existing `.omp/<TOPIC>-PLAN.md`: `skill://executing-plans`.
- Independent parallelizable slices: `skill://dispatching-parallel-agents`.
- Feature or bugfix in a language with a test runner: `skill://test-driven-development`.
- Diagnosing a defect: `skill://systematic-debugging`.

Self-written pack — the seven managed skills, also auto-nudged by the `lang-*`
rules where noted:

- A repository moved to a new absolute path: `skill://omp-project-migration`
  (migrate memory bank, sessions and history before resuming there).
- Unattributed Nix eval/build warnings: `skill://tracing-nix-eval-warnings`
  (also nudged by `lang-nix`).
- Changes to this config's omp wiring (`assets/omp/`, `modules/features/ai.nix`,
  skills packaging): `skill://omp-rule-and-skill-probe` (also nudged by `lang-nix`).
- Bash driving pactl or PipeWire: `skill://pactl-bash-daemon` (also nudged by
  `lang-shell`).
- DankMaterialShell plugin changes: `skill://verifying-dms-plugin-changes`.
- End of a coding task: `skill://end-of-task-memory-update` alongside the
  retain/learn write.
- A fetch via `read`, `browser` or `web_search` hits a Cloudflare challenge,
  403/503 or any anti-bot wall — or returns an empty/stub shell (JS SPA): read
  `skill://cloudflare-bypass` and route the fetch through the Scrapling MCP
  server. Normal omp searching still happens; when a result comes back
  blocked, follow up by fetching that URL through the skill, never dropping it.
