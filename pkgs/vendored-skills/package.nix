{
  lib,
  fetchurl,
  runCommandLocal,
  nixos-skill,
  vercel-skills,
  wshobson-agents,
}:
let
  createReadmeSkill = fetchurl {
    url = "https://raw.githubusercontent.com/github/awesome-copilot/634b92f887487fc61cddc2f61d77830e09e8f589/skills/create-readme/SKILL.md";
    hash = "sha256-qT+RYb7zJOOhVQ/HnU8BtmCj+36txEVWd9ms5NopZaw=";
  };

  droppedNixosFiles = [
    ".github"
    ".gitignore"
    "README.md"
    "install.sh"
    "scripts"
    "references/release-process.md"
  ];

  rewrites = {
    "nixos/SKILL.md" = [
      {
        from = ''
          ### Release Process

          | Topic | File |
          |-------|------|
          | NixOS release process, roles, branch-off, beta, freeze | **`references/release-process.md`** |

        '';
        to = "";
      }
    ];

    "uv-package-manager/references/advanced-patterns.md" = [
      {
        from = ''

          # Commit updated files
          git add pyproject.toml uv.lock
          git commit -m "Add new-package dependency"'';
        to = "";
      }
    ];

    "find-skills/SKILL.md" = [
      {
        from = ''
          - `npx skills add <package>` - Install a skill from GitHub or other sources
          - `npx skills update` - Update all installed skills
        '';
        to = "";
      }
      {
        from = "3. The install command they can run";
        to = "3. The source repository and the skill's path inside it";
      }
      {
        from = ''
          To install it:
          npx skills add vercel-labs/agent-skills@react-best-practices
        '';
        to = ''
          Source: vercel-labs/agent-skills, skill path react-best-practices
        '';
      }
      {
        from = ''
          ### Step 6: Offer to Install

          If the user wants to proceed, you can install the skill for them:

          ```bash
          npx skills add <owner/repo@skill> -g -y
          ```

          The `-g` flag installs globally (user-level) and `-y` skips confirmation prompts.'';
        to = ''
          ### Step 6: Hand the Source Over, Do Not Install

          Skills here are vendored declaratively. The `skills` CLI installer writes into a
          directory nothing reads and leaves unmanaged state behind, so never invoke it.
          Report the source repository and the skill's path inside it, and offer to add that
          repository as an input so the skill is built into the skills package.'';
      }
      {
        from = "3. Suggest the user could create their own skill with `npx skills init`";
        to = "3. Offer to capture the workflow as a managed skill instead";
      }
      {
        from = ''
          If this is something you do often, you could create your own skill:
          npx skills init my-xyz-skill'';
        to = "If this is something you do often, I can capture it as a managed skill.";
      }
    ];
  };

  applyRewrites = lib.concatLines (
    lib.mapAttrsToList (
      file: subs:
      lib.concatStringsSep " \\\n" (
        [ "substituteInPlace $out/${file}" ]
        ++ map (s: "  --replace-fail ${lib.escapeShellArg s.from} ${lib.escapeShellArg s.to}") subs
      )
    ) rewrites
  );

  bannedEverywhere = [
    "git commit"
    "git push"
    "npx skills add"
    "npx skills init"
    "npx skills update"
    "(^|[^/])references/"
  ];

  bannedInSkillFiles = [
    "git add"
    "\\]\\(\\.\\./"
    "release-process"
  ];

  gate = include: patterns: ''
    for pattern in ${lib.escapeShellArgs patterns}; do
      if grep -rnE --include=${lib.escapeShellArg include} -- "$pattern" $out; then
        echo "vendored-skills: banned pattern '$pattern' present in ${include} at the sites above" >&2
        exit 1
      fi
    done
  '';
in
runCommandLocal "vendored-skills"
  {
    meta = {
      description = "Third-party agent skills, with sibling paths normalised to skill:// URLs and imperative install steps removed";
      platforms = lib.platforms.all;
    };
  }
  ''
    mkdir -p $out

    cp -r ${nixos-skill} $out/nixos
    cp -r ${vercel-skills}/skills/find-skills $out/find-skills
    cp -r ${wshobson-agents}/plugins/python-development/skills/. $out/
    install -Dm644 ${createReadmeSkill} $out/create-readme/SKILL.md

    chmod -R u+w $out

    rm -rf ${lib.concatMapStringsSep " " (f: "$out/nixos/${f}") droppedNixosFiles}
    ${applyRewrites}

    for dir in $out/*/; do
      name=$(basename "$dir")
      [ -f "$dir/SKILL.md" ] || continue
      find "$dir" -name '*.md' -exec sed -i -E \
        -e "s#\]\(\.\./([A-Za-z0-9_-]+)/SKILL\.md\)#](skill://\1)#g" \
        -e "s#(\.\./)+references/#skill://$name/references/#g" \
        -e "s#(^|[^/])references/#\1skill://$name/references/#g" \
        {} +
    done

    ${gate "*.md" bannedEverywhere}
    ${gate "SKILL.md" bannedInSkillFiles}

    unresolved=0
    for target in $(grep -rhoE 'skill://[A-Za-z0-9_./-]+' --include='*.md' $out | sort -u); do
      [ -e "$out/''${target#skill://}" ] && continue
      echo "vendored-skills: '$target' resolves to nothing:" >&2
      grep -rnF --include='*.md' -- "$target" $out >&2
      unresolved=1
    done
    [ "$unresolved" -eq 0 ]
  ''
