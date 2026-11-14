#!/usr/bin/env bash

queue=$1
store=$2
status=0
shopt -s nullglob
for entry in "$queue"/*; do
  name=${entry##*/}
  if [[ ! -L $entry || ! $name =~ ^[0123456789abcdfghijklmnpqrsvwxyz]{32}-[a-zA-Z0-9+._?=-]+$ ]]; then
    printf 'attic upload: ignoring invalid entry %s\n' "$entry" >&2
    status=1
    continue
  fi
  target=$(readlink -- "$entry") || {
    status=1
    continue
  }
  if [[ $target != "$store/$name" ]]; then
    printf 'attic upload: ignoring invalid target for %s\n' "$entry" >&2
    status=1
    continue
  fi
  if attic push --no-closure homelab:shared "$target"; then
    if ! rm -- "$entry"; then
      printf 'attic upload: cannot remove %s\n' "$entry" >&2
      status=1
    fi
  else
    printf 'attic upload: upload failed for %s\n' "$target" >&2
    status=1
  fi
done
exit "$status"
