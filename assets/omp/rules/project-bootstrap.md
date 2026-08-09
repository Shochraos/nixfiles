---
alwaysApply: true
---

# Project bootstrap

When starting work in a repository that has no `.omp/` directory, or when
creating a new project: analyse it before doing anything else, then create the
three project files. Analysis first — a bootstrap written from assumptions is
worse than none.

Read enough to be concrete: build and run entry points, how it is tested, the
directory layout, the naming and style conventions actually in use, and recent
history for decisions already made.

## Files to create

All three live in `.omp/` at the **repository root**. A nested `.omp/` becomes
the nearest non-empty one and shadows the root files, so never create one in a
subdirectory.

- **`.omp/AGENTS.md`** — the project's state. What it is, how it is built, run
  and verified, its layout and conventions, and a running ledger of non-obvious
  findings, completed work, and designs that were rejected and why. Long
  background belongs here; it costs context once.
- **`.omp/WATCHDOG.md`** — advisor-only review priorities, never injected into
  the main context. Order it as a priority ladder, because the advisor emits at
  most one note per cycle: false claims in a written record first, then silent
  failures, then unsupported inference, then hard rules, then scope drift. End
  with an explicit do-not-raise list covering everything the formatter, linter
  or type checker already gates. Import the hard rules with `@RULES.md` rather
  than duplicating them; never import `AGENTS.md`, it is too large.
- **`.omp/RULES.md`** — only short, hard, always-on constraints. It is
  re-attached near every turn, so keep it to the handful of requirements that
  must never scroll out of reach. This file is sticky only while no
  `~/.omp/agent/RULES.md` exists; never create that user-level file, it would
  shadow every project's `RULES.md`.

## Gitignore

Add `.omp/` to `.gitignore`, creating the file if it does not exist. Do not
commit the change; report it.

## Maintenance

Whenever a turn produces something worth retaining, update `.omp/AGENTS.md` and
`.omp/WATCHDOG.md` in that same step if either is now stale or incomplete.
The memory write and the written record are one action, not two.
