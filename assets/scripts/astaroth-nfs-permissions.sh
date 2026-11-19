#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
unset CDPATH POSIXLY_CORRECT
shopt -s dotglob nullglob

usage() {
  printf '%s\n' \
    'Usage: bash astaroth-nfs-permissions.sh [--apply-quiesced] root {appdata|backups|data|misc}' \
    '       bash astaroth-nfs-permissions.sh [--apply-quiesced] projects' \
    '       bash astaroth-nfs-permissions.sh [--apply-quiesced] project CHECKOUT[/SUBDIR...]' \
    'Default: preflight only. Apply locally on Unraid after backing up ACLs and stopping writers, mover and mount changes.' \
    'root changes only access; projects sets access and inheritance at the projects root.' \
    'project opts in an existing checkout (with its own .git directory); review all skips before applying.' \
    'Creation modes must allow group write for shared editing (often umask 0002).'
}
die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}
skip() { printf 'Skip %q: %s\n' "$1" "$2"; }

apply=false
if [[ ${1-} == --apply-quiesced ]]; then
  apply=true
  shift
fi
share=/mnt/user
recurse=false
inherit=false
case ${1-}:$# in
--help:1 | -h:1)
  usage
  exit
  ;;
root:2)
  case $2 in
  appdata | backups | data | misc) target=$share/$2 ;;
  *) die 'Choose appdata, backups, data or misc.' ;;
  esac
  ;;
projects:1)
  target=$share/projects
  inherit=true
  ;;
project:2)
  case /$2/ in
  *//* | */.* | *[[:cntrl:]]*) die 'Use a relative checkout path without hidden, empty, . or .. components.' ;;
  esac
  target=$share/projects/$2
  inherit=true
  recurse=true
  ;;
*)
  usage >&2
  exit 2
  ;;
esac
for tool in findmnt stat getfacl setfacl; do
  command -v "$tool" >/dev/null || die "Missing required tool: $tool"
done
mount=$(findmnt -knro ID,FSTYPE --mountpoint "$share") || die "Not a mountpoint: $share"
[[ $mount =~ ^[0-9]+\ fuse\.shfs$ ]] || die "Expected an Unraid shfs mount at $share."
cd -Pe -- "$target" || die "Not an accessible directory: $target"
[[ $PWD == "$target" ]] || die "Refusing symlinked path: $target"
[[ $(findmnt -knro ID --target .) == "${mount%% *}" ]] || die "Refusing a separate or unknown mount: $target"

if $recurse; then
  [[ ! -L .git && -d .git ]] || die "$target must have its own physical .git directory. Linked worktrees are out of scope."
fi
declare -A mountpoints acl
while read -r _ _ _ _ mount_path _; do
  printf -v mount_path '%b' "$mount_path"
  if [[ $mount_path == "$target/"* ]]; then
    relative_mount=.${mount_path#"$target"}
    mountpoints[$relative_mount]=1
  fi
done </proc/self/mountinfo

rwx() {
  local chars=rwx result='' bit
  for bit in 4 2 1; do
    if (($1 & bit)); then result+=${chars:0:1}; else result+=-; fi
    chars=${chars:1}
  done
  REPLY=$result
}
metadata() { stat -c '%d:%i %a %u %g %h' -- "$1"; }
read_acl() {
  listing=$(getfacl -cnE -- "$1") || die "Cannot read ACL: $1"
  acl=()
  local line key perm bits
  while IFS= read -r line; do
    [[ -n $line ]] || continue
    if ! $inherit && [[ $line == default:* ]]; then continue; fi
    [[ $line =~ ^(default:)?(user:(99|1000)?|(group|other|mask):):[r-][w-][x-]$ ]] ||
      die "$1: ACL contains entries outside the supported policy; review manually."
    key=${line%:*} perm=${line##*:} bits=0
    if [[ $perm == r* ]]; then bits=4; fi
    if [[ $perm == ?w* ]]; then bits=$((bits | 2)); fi
    if [[ $perm == ??x ]]; then bits=$((bits | 1)); fi
    acl[$key]=$bits
  done <<<"$listing"
  [[ -v 'acl[user:]' && -v 'acl[group:]' && -v 'acl[other:]' ]] || die "$1: incomplete ACL."
}

plan() {
  local path=$1 dir=$2 scope want mask mask_new group_bits other_bits uid key grant users
  spec='' stage='' expected_mode=$mode
  for scope in '' default:; do
    want=7
    if [[ $scope == default: ]]; then
      if ! $inherit || ! $dir; then break; fi
      if [[ ! -v 'acl[default:user:]' ]]; then
        spec+=default:user::rwx,default:group::---,default:other::---,default:user:99:rwx,default:user:1000:rwx,default:mask::rwx,
        break
      fi
      [[ ${acl["default:user:"]} == 7 ]] || die "$path: default owner ACL is restrictive; review manually."
    elif ! $dir; then want=6; fi
    group_bits=${acl["${scope}group:"]}
    other_bits=${acl["${scope}other:"]}
    mask=${acl["${scope}mask:"]-$group_bits}
    users=
    for uid in 99 1000; do
      key=${scope}user:$uid
      if [[ -z $scope && $uid == "$owner" ]]; then continue; fi
      if [[ -v 'acl['"$key"']' ]]; then
        if (((acl[$key] & mask & want) == want)); then continue; fi
        grant=$((acl[$key] | want))
      elif [[ -z $scope && $group == 100 ]] && (((group_bits & mask & want) == want)); then
        continue
      else
        grant=$want
        if ((want == 6)); then
          if [[ $group != 100 ]] && ((((group_bits & mask) ^ other_bits) & 1)); then
            skip "$path" 'cannot infer existing execute access for both UIDs'
            return 1
          fi
          grant=$((want | (group_bits & mask & 1)))
        fi
      fi
      rwx "$grant"
      users+=$key:$REPLY,
    done
    [[ -n $users ]] || continue
    mask_new=$((mask | want))
    (((group_bits & (mask_new ^ mask)) == 0)) || die "$path: ${scope}ACL mask would unmask the owning group."
    if [[ -z $scope ]]; then
      if [[ ! -v 'acl[mask:]' && $mask_new != "$mask" ]]; then
        rwx "$mask"
        stage=${users}mask::$REPLY
      fi
      expected_mode=$(((mode & ~070) | (mask_new << 3)))
    fi
    rwx "$mask_new"
    spec+=$users${scope}mask::$REPLY,
  done
  spec=${spec%,}
}

declare -a paths=() specs=() stages=() before=() before_acls=() modes=() directories=()
visit() {
  local path=$1 in_git=$2 name=${1##*/} dir=false meta inode mode owner group links child
  local listing spec stage expected_mode REPLY
  if [[ -n ${mountpoints[$path]-} ]]; then
    [[ $path != ./.git ]] || die 'Checkout .git is a separate mount.'
    skip "$path" 'nested mount'
    return
  fi
  if [[ -L $path ]]; then
    skip "$path" 'symlink'
    return
  fi
  if [[ $name == .git ]]; then
    if [[ ! -d $path ]]; then
      skip "$path" 'external Git metadata'
      return
    fi
    in_git=true
  fi
  if $in_git; then
    case $name in
    hooks | config | config.worktree | modules | worktrees)
      skip "$path" 'protected Git metadata'
      return
      ;;
    *.lock) die "$path: Git lock present; stop writers and investigate before retrying." ;;
    esac
    if [[ $path == */.git/objects/* && ! -d $path ]]; then
      skip "$path" 'immutable Git object or object-store metadata'
      return
    fi
  fi
  case $name in
  .env | .env.* | .ssh | .gnupg | .aws | .kube | .docker | .netrc | .git-credentials | .npmrc | .pypirc | id_rsa* | id_ed25519* | credentials* | secrets* | *.pem | *.key | *.p12 | *.pfx | *.kdbx)
    skip "$path" 'possible credentials'
    return
    ;;
  esac
  if [[ -d $path ]]; then
    dir=true
  elif [[ ! -f $path ]]; then
    skip "$path" 'not a regular file or directory'
    return
  fi
  meta=$(metadata "$path") || die "Cannot stat: $path"
  read -r inode mode owner group links <<<"$meta"
  mode=$((8#$mode))
  if $dir; then
    if (((mode & 0700) != 0700)); then
      if ! $recurse || [[ $path == . || $path == ./.git ]]; then
        die "$path: owner needs rwx; named ACLs cannot override the owner entry."
      fi
      skip "$path" 'owner lacks rwx'
      return
    fi
    if $recurse && (((mode & 01050) != 0050 || (group != 100 && (mode & 005) != 005))); then
      [[ $path != . && $path != ./.git ]] || die "$path: sticky or restrictive checkout root or .git directory; review manually."
      skip "$path" 'sticky or restrictive directory'
      return
    fi
    if (((mode & 02000) != 0 && EUID != 0)) && [[ " ${GROUPS[*]} " != *" $group "* ]]; then
      die "$path: cannot guarantee setgid preservation with this identity."
    fi
  elif [[ $links != 1 ]] || (((mode & 07000) != 0 || (mode & 0640) != 0640 || (group != 100 && (mode & 004) == 0))); then
    skip "$path" 'hardlinked, special-mode or restrictive file'
    return
  fi
  read_acl "$path"
  if ! plan "$path" "$dir"; then return; fi
  if [[ -n $spec ]]; then
    printf 'Plan %q: %s\n' "$path" "$spec"
    setfacl --test -n -m "$spec" -- "$path" >/dev/null || die "ACL preflight failed: $path"
    paths+=("$path")
    specs+=("$spec")
    stages+=("$stage")
    before+=("$meta")
    before_acls+=("$listing")
    modes+=("$expected_mode")
    directories+=("$dir")
  fi
  if $recurse && $dir; then
    [[ -r $path && -x $path ]] || die "Cannot enumerate: $path"
    for child in "$path"/*; do visit "$child" "$in_git"; done
  fi
}

printf 'Target: %s\n' "$target"
visit . false
if ! $apply; then
  printf 'Preflight only; %s path(s) would change.\n' "${#paths[@]}"
  exit 0
fi

for i in "${!paths[@]}"; do
  path=${paths[i]}
  [[ ! -L $path && $(metadata "$path") == "${before[i]}" ]] || die "$path: changed after preflight; stop and inspect earlier writes."
  read_acl "$path"
  [[ $listing == "${before_acls[i]}" ]] || die "$path: ACL changed after preflight; stop and inspect earlier writes."
  if [[ -n ${stages[i]} ]]; then
    setfacl -n -m "${stages[i]}" -- "$path" || die "$path: cannot establish POSIX ACL support without widening the existing mode."
    read_acl "$path"
    [[ -v 'acl[mask:]' && $(metadata "$path") == "${before[i]}" ]] || die "$path: ACL staging did not preserve the mode; inspect the backup."
  fi
  setfacl -n -m "${specs[i]}" -- "$path" || die "$path: ACL write failed; the selected tree may be partially updated."
  read -r inode _ owner group links <<<"${before[i]}"
  printf -v expected '%s %o %s %s %s' "$inode" "${modes[i]}" "$owner" "$group" "$links"
  [[ $(metadata "$path") == "$expected" ]] || die "$path: metadata readback mismatch; inspect the backup."
  mode=${modes[i]}
  read_acl "$path"
  plan "$path" "${directories[i]}" && [[ -z $spec ]] || die "$path: ACL readback mismatch; inspect the backup."
done
printf 'Verified: %s path(s) changed.\n' "${#paths[@]}"
