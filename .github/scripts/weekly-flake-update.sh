#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

mode=$1
artifact=$2
base=${GITHUB_SHA:?}
[[ $(git rev-parse HEAD) == "$base" ]] || fail 'Checkout does not match the workflow base.'
[[ $(git ls-tree "$base" -- flake.lock) == '100644 blob '* ]] || fail 'Base must track a regular flake.lock.'

if [[ $mode == prepare ]]; then
  nix flake update
  changes=$(git status --porcelain --untracked-files=all)
  case $changes in
  '')
    printf 'No change to flake.lock at %s\n' "$base"
    exit 0
    ;;
  ' M flake.lock') ;;
  *) fail 'Flake update changed paths or metadata other than flake.lock contents.' ;;
  esac
  [[ -f flake.lock && ! -L flake.lock ]] || fail 'Updated flake.lock is not a regular file.'
  mkdir -- "$artifact"
  cp -- flake.lock "$artifact/flake.lock"
fi

lock=$artifact/flake.lock
[[ -f $lock && ! -L $lock ]] || fail 'Candidate flake.lock is missing or not a regular file.'
sha256=$(sha256sum <"$lock")
sha256=${sha256%% *}
if [[ $mode != prepare ]]; then
  [[ $sha256 == "$4" ]] || fail 'Candidate lock digest does not match prepare output.'
fi

scratch=$(mktemp -d "${RUNNER_TEMP:?}/flake-update.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
export GIT_INDEX_FILE="$scratch/index"
git read-tree "$base"
blob=$(git hash-object -w --no-filters -- "$lock")
git update-index --cacheinfo "100644,$blob,flake.lock"
tree=$(git write-tree)
base_tree=$(git rev-parse "$base^{tree}")
[[ $tree != "$base_tree" ]] || fail 'Candidate tree is unchanged.'
export GIT_AUTHOR_NAME='github-actions[bot]' GIT_COMMITTER_NAME='github-actions[bot]'
export GIT_AUTHOR_EMAIL='41898282+github-actions[bot]@users.noreply.github.com'
export GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL
GIT_AUTHOR_DATE=$(git show -s --format=%cI "$base")
export GIT_AUTHOR_DATE GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE
commit=$(git -c commit.gpgSign=false -c i18n.commitEncoding=UTF-8 commit-tree "$tree" -p "$base" -m 'chore: update flake.lock')
unset GIT_INDEX_FILE

printf 'base=%s\nsha256=%s\ncommit=%s\n' "$base" "$sha256" "$commit" >"$scratch/identity"
if [[ $mode == prepare ]]; then
  cp -- "$scratch/identity" "$artifact/identity"
  printf 'commit=%s\nsha256=%s\n' "$commit" "$sha256" >>"$GITHUB_OUTPUT"
else
  [[ $commit == "$3" ]] || fail 'Recreated commit does not match the expected candidate.'
  if [[ ! -f "$artifact/identity" || -L "$artifact/identity" ]] ||
    ! cmp -s -- "$scratch/identity" "$artifact/identity"; then
    fail 'Artifact identity does not match the recreated candidate.'
  fi
fi
printf 'Candidate identity:\n'
cat -- "$scratch/identity"

if [[ $mode == publish ]]; then
  export EXPECTED_BASE=$base EXPECTED_CANDIDATE=$commit
  cat >"$scratch/pre-push" <<'HOOK'
#!/usr/bin/env bash
if ! read -r _ local_oid remote_ref remote_oid ||
  [[ "$local_oid" != "$EXPECTED_CANDIDATE" || "$remote_ref" != refs/heads/main || "$remote_oid" != "$EXPECTED_BASE" ]]; then
  printf 'Refusing to publish: main is not at the tested base. Dispatch a fresh run from main.\n' >&2
  exit 1
fi
HOOK
  chmod +x "$scratch/pre-push"
  git -c core.hooksPath="$scratch" push --no-follow-tags origin "$commit:refs/heads/main"
fi
