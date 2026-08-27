---
alwaysApply: true
---

# Design workflow

Run this gate on EVERY task, before the first edit or write, and state the
verdict in one line: `Design gate: brainstorming <needed|skipped> — <reason>`.
Not running it is itself a violation; a wrong verdict is recoverable, an
unstated one is not.

Needed when any of these holds:

- a new file, module, aspect, dependency, or subsystem
- an interface, option, or schema change
- a behaviour change, or work touching more than one module
- the request admits two reasonable readings
- you are about to decide anything the user did not specify: naming, scope,
  defaults, which host or target, the meaning of an ambiguous phrase

Skipped only for read-only investigation, a mechanical single-file fix with no
design choice, continuing an already-approved plan, or on the user's say-so.

Judge scope, never difficulty. "Small", "two files" and "clear request" are not
exemptions — `skill://brainstorming` carries a HARD-GATE that holds regardless
of perceived simplicity, so if you are weighing how hard the work is you are
answering the wrong question.

When needed: `recall` first, then read the project's own record of prior
decisions, then invoke `skill://brainstorming`.

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
  refresh `README.md` with `skill://create-readme`, then report. Leave
  integration to the user.
- The README refresh runs after every completed coding workflow, not after
  read-only investigation. `skill://create-readme` writes a README from
  scratch, so treat the existing one as the baseline: keep hand-written
  sections that are still accurate and rewrite only what this change made
  stale. No `README.md` yet means create one.

Skill handoffs are written `superpowers:<name>`; in omp the skill is `<name>`,
so read `skill://<name>`.

`skill://systematic-debugging` is a second entrypoint, for diagnosing a defect.
It has no git steps; follow it as written, then finish through the same
Finishing bullet above, README included.
