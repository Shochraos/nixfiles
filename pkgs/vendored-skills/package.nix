{
  lib,
  runCommandLocal,
  nixos-skill,
  vercel-skills,
  wshobson-agents,
}:
let
  droppedNixosFiles = [
    ".github"
    ".gitignore"
    "README.md"
    "install.sh"
    "scripts"
    "references/release-process.md"
  ];

  excisions = {
    "nixos/SKILL.md" = ''
      ### Release Process

      | Topic | File |
      |-------|------|
      | NixOS release process, roles, branch-off, beta, freeze | **`references/release-process.md`** |

    '';

    "uv-package-manager/references/advanced-patterns.md" = ''

      # Commit updated files
      git add pyproject.toml uv.lock
      git commit -m "Add new-package dependency"
    '';
  };

  applyExcisions = lib.concatLines (
    lib.mapAttrsToList (
      file: text: "substituteInPlace $out/${file} --replace-fail ${lib.escapeShellArg text} ${lib.escapeShellArg ""}"
    ) excisions
  );

  bannedInSkillFiles = [
    "git add"
    "git commit"
    "git push"
    "(^|[^/])references/"
    "\\]\\(\\.\\./"
    "release-process"
  ];

  bannedEverywhere = [
    "git commit"
    "git push"
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
      description = "Third-party agent skills vendored verbatim, with sibling paths normalised to skill:// URLs";
      platforms = lib.platforms.all;
    };
  }
  ''
    mkdir -p $out

    cp -r ${nixos-skill} $out/nixos
    cp -r ${vercel-skills}/skills/find-skills $out/find-skills
    cp -r ${wshobson-agents}/plugins/python-development/skills/. $out/

    chmod -R u+w $out

    rm -rf ${lib.concatMapStringsSep " " (f: "$out/nixos/${f}") droppedNixosFiles}
    ${applyExcisions}

    for dir in $out/*/; do
      name=$(basename "$dir")
      [ -f "$dir/SKILL.md" ] || continue
      sed -i -E \
        -e "s#\`(\.\./)?references/#\`skill://$name/references/#g" \
        -e 's#\]\(\.\./([a-z0-9-]+)/SKILL\.md\)#](skill://\1)#g' \
        "$dir/SKILL.md"
    done

    ${gate "SKILL.md" bannedInSkillFiles}
    ${gate "*.md" bannedEverywhere}
  ''
