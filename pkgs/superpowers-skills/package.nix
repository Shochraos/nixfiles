{
  lib,
  runCommandLocal,
  src,
}:
let
  version = (builtins.fromJSON (builtins.readFile "${src}/package.json")).version;

  droppedSkills = [
    "subagent-driven-development"
    "finishing-a-development-branch"
    "using-superpowers"
  ];

  rewrites = {
    "brainstorming/SKILL.md" = [
      {
        from = "6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit";
        to = "6. **Write design doc** — save to `.omp/<TOPIC>-PLAN.md` at the repository root";
      }
      {
        from = "- Write the validated design (spec) to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`";
        to = "- Write the validated design (spec) to `.omp/<TOPIC>-PLAN.md` at the repository root";
      }
      {
        from = "- Commit the design document to git";
        to = "- Leave the design document uncommitted";
      }
      {
        from = "Spec written and committed to";
        to = "Spec written to";
      }
      {
        from = "`skills/brainstorming/visual-companion.md`";
        to = "`skill://brainstorming/visual-companion.md`";
      }
    ];

    "brainstorming/spec-document-reviewer-prompt.md" = [
      {
        from = "**Dispatch after:** Spec document is written to docs/superpowers/specs/";
        to = "**Dispatch after:** Spec document is written to `.omp/<TOPIC>-PLAN.md`";
      }
    ];

    "executing-plans/SKILL.md" = [
      {
        from = "**Note:** Tell your human partner that Superpowers works much better with access to subagents (Claude Code, Codex CLI, Codex App, Copilot CLI, and Gemini CLI all qualify; see the per-platform tool refs in `../using-superpowers/references/`). If subagents are available, use superpowers:subagent-driven-development instead of this skill.";
        to = "**Note:** This runtime has subagents. Dispatch independent slices with superpowers:dispatching-parallel-agents and keep the rest of this skill.";
      }
      {
        from = "1. Ensure an isolated workspace: use superpowers:using-git-worktrees to create one or verify the existing one";
        to = "1. Work in the current checkout. A worktree is opt-in: use superpowers:using-git-worktrees only when the user asks for one";
      }
      {
        from = "using the finishing-a-development-branch skill to complete this work";
        to = "reporting the result to the user";
      }
      {
        from = ''
          - **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
          - Follow that skill to verify tests, present options, execute choice'';
        to = "- Run the verification gate for this project, retain what was learned, then report the diff. Leave integration to the user.";
      }
    ];

    "requesting-code-review/SKILL.md" = [
      {
        from = "  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md";
        to = "  PLAN_OR_REQUIREMENTS: Task 2 from .omp/DEPLOYMENT-PLAN.md";
      }
    ];

    "using-git-worktrees/SKILL.md" = [
      {
        from = "**If NOT ignored:** Add to .gitignore, commit the change, then proceed.";
        to = "**If NOT ignored:** Add to .gitignore and tell the user. Do not commit.";
      }
    ];

    "writing-plans/SKILL.md" = [
      {
        from = "**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`";
        to = "**Save plans to:** the same `.omp/<TOPIC>-PLAN.md` file that holds the spec";
      }
      {
        from = "> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.";
        to = "> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task, dispatching independent slices with superpowers:dispatching-parallel-agents.";
      }
      {
        from = ''- "Commit" - step'';
        to = "- (no commit step)";
      }
      {
        from = ''
          - [ ] **Step 5: Commit**

          ```bash
          git add tests/path/test.py src/path/file.py
          git commit -m "feat: add specific feature"
          ```'';
        to = "- [ ] **Step 5: Report the change to the user (no commit)**";
      }
      {
        from = ''**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**'';
        to = ''**"Plan complete and saved to the plan file. Two execution options:**'';
      }
      {
        from = "**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration";
        to = "**1. Parallel (recommended)** - independent slices dispatched concurrently with the native task tool";
      }
      {
        from = ''
          **If Subagent-Driven chosen:**
          - **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
          - Fresh subagent per task + two-stage review'';
        to = ''
          **If Parallel chosen:**
          - **REQUIRED SUB-SKILL:** Use superpowers:dispatching-parallel-agents
          - One native task subagent per independent slice'';
      }
    ];

    "writing-skills/SKILL.md" = [
      {
        from = "**Personal skills live in your runtime's skills directory** (`~/.claude/skills/` on Claude Code) — see [codex-tools.md](../using-superpowers/references/codex-tools.md) or [gemini-tools.md](../using-superpowers/references/gemini-tools.md) for the path on those runtimes. Codex, Copilot CLI, and Gemini CLI all also recognize `~/.agents/skills/` as a cross-runtime alias.";
        to = "**Personal skills live in your runtime's skills directory** (`~/.omp/agent/skills/` for omp; `~/.omp/agent/managed-skills/` for skills the agent mints itself).";
      }
      {
        from = "- [ ] Commit skill to git and push to your fork (if configured)";
        to = "- [ ] Report the new skill to the user; leave committing to them";
      }
    ];
  };

  banned = [
    "docs/superpowers"
    "skills/brainstorming/"
    "superpowers:subagent-driven-development"
    "superpowers:finishing-a-development-branch"
    "git add"
    "git commit"
    "git push"
  ];

  applyRewrites = lib.concatLines (
    lib.mapAttrsToList (
      file: subs:
      lib.concatStringsSep " \\\n" (
        [ "substituteInPlace $out/${file}" ]
        ++ map (s: "  --replace-fail ${lib.escapeShellArg s.from} ${lib.escapeShellArg s.to}") subs
      )
    ) rewrites
  );
in
runCommandLocal "superpowers-skills-${version}"
  {
    meta = {
      description = "Superpowers agent skills, with the git-integration steps removed";
      homepage = "https://github.com/obra/superpowers";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
  ''
    cp -r ${src}/skills $out
    chmod -R u+w $out
    rm -rf ${lib.concatMapStringsSep " " (name: "$out/${name}") droppedSkills}

    ${applyRewrites}

    for pattern in ${lib.escapeShellArgs banned}; do
      if grep -rnF --include='*.md' -- "$pattern" $out; then
        echo "superpowers-skills: upstream reintroduced '$pattern' at the sites above" >&2
        exit 1
      fi
    done
  ''
