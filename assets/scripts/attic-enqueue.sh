#!/usr/bin/env bash

queue=$1
store=$2
set -f
for output in ${OUT_PATHS:-}; do
  name=${output##*/}
  if [[ $output != "$store/$name" || ! $name =~ ^[0123456789abcdfghijklmnpqrsvwxyz]{32}-[a-zA-Z0-9+._?=-]+$ ]]; then
    printf 'attic enqueue: invalid output %s\n' "$output" >&2
    continue
  fi
  if ! ln -sT -- "$output" "$queue/$name" 2>/dev/null; then
    if [[ ! -L $queue/$name || $(readlink -- "$queue/$name") != "$output" ]]; then
      printf 'attic enqueue: cannot queue %s\n' "$output" >&2
    fi
  fi
done
exit 0
