---
condition: "**/SKILL.md"
interruptMode: never
---
A SKILL.md is being edited or written. In agent-skills-nix these files are
payload source: an edit there must keep the payload consistent — run the gates
(`nix flake check` builds the banned-pattern and `skill://`-resolution gates)
and, for a skill no `lang-*` rule auto-nudges, add its trigger bullet to
`rule://skills` in the same change. Never hand-edit skills under
`~/.omp/agent/managed-skills/` — manage them with `manage_skill` and promote
into the payload instead (see `rule://skills`).
