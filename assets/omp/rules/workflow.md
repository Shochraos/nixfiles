---
alwaysApply: true
---

# Design workflow

Before a new subsystem, an interface change, or work spanning more than one
module: `recall` first, then read the project's own record of prior decisions,
then invoke `skill://brainstorming`.

The chain runs brainstorming -> writing-plans and stops there.

- Both the spec and the plan go in one file at the repository root:
  `.omp/<TOPIC>-PLAN.md`. Never `docs/superpowers/`. Never a nested `.omp/`.
- Never write a commit step into a plan.
- A git worktree is opt-in. Do not create one unless asked.
- Execute with the native `task` and `todo` tools.
- A new dependency means the flake is updated in the same change: tooling into
  `devShells.default`, a runtime input into `packages.default`. Never install
  one ad hoc or globally. Language-level libraries the project already tracks
  in its own manifest or lockfile stay there.
- Verification means the verification gate this project already defines, run
  and read before any claim of success, not a generic test command.
- Finishing means: formatter, project checks, then bring `.omp/AGENTS.md` and
  `.omp/WATCHDOG.md` up to date in the same step as the memory write, then
  report. Leave integration to the user.

Skill handoffs are written `superpowers:<name>`; in omp the skill is `<name>`,
so read `skill://<name>`.

`skill://systematic-debugging` is a second entrypoint, for diagnosing a defect.
It has no git steps; follow it as written.
