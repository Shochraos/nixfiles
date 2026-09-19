---
condition: '"action"\s*:\s*"(create|update)"'
scope:
  - tool:manage_skill
  - tool:learn
interruptMode: never
---
A managed skill was just created or updated. Before the task ends, present the
finished SKILL.md to the user and offer to promote it into the agent-skills-nix
repo (`skills/<name>/`, verbatim copy) as a `managed-skills` payload entry —
see `rule://skills`. Until promoted it exists only in
`~/.omp/agent/managed-skills/`: no git history, no delivery to other machines,
and it can be pruned or lost with the agent directory.

Once the skill is in agent-skills-nix, delete the managed copy with
`manage_skill` delete in the same change — the repo is the single source of
truth, whether or not the payload is live yet.
