#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES="$BASE_DIR/sources.md"
CLONES_DIR="$BASE_DIR/clones"

mkdir -p "$CLONES_DIR"

repos=$(grep -oE 'https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' "$SOURCES" | sort -u)

if [ -z "$repos" ]; then
  printf 'No GitHub repos found in %s\n' "$SOURCES" >&2
  exit 1
fi

failures=0

while IFS= read -r url; do
  rel="${url#https://github.com/}"
  owner="${rel%%/*}"
  repo="${rel#*/}"
  dir_name="${owner}-${repo}"
  dest="$CLONES_DIR/$dir_name"

  if [ -d "$dest/.git" ]; then
    printf '== Pulling %s -> %s\n' "$url" "$dest"
    if ! git -C "$dest" pull --ff-only; then
      printf '!! Pull failed: %s\n' "$url" >&2
      failures=$((failures + 1))
    fi
  else
    printf '== Cloning %s -> %s\n' "$url" "$dest"
    if ! git clone "$url.git" "$dest"; then
      printf '!! Clone failed: %s\n' "$url" >&2
      failures=$((failures + 1))
    fi
  fi
done <<< "$repos"

if [ "$failures" -gt 0 ]; then
  printf 'Done with %d error(s).\n' "$failures" >&2
  exit 1
fi

printf 'All %s repos are up to date in %s\n' "$(printf '%s\n' "$repos" | wc -l | tr -d ' ')" "$CLONES_DIR"
