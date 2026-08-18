#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES="$BASE_DIR/sources.md"
CLONES_DIR="$BASE_DIR/clones"

mkdir -p "$CLONES_DIR"

current=""
count=0
failures=0

while IFS= read -r line; do
  # Section heading "## <class>" switches the target class dir.
  # MUST match before the comment skip: headings also start with '#'.
  if [[ "$line" =~ ^##[[:space:]]+([A-Za-z0-9_-]+) ]]; then
    current="${BASH_REMATCH[1]}"
    continue
  fi

  # Skip blank lines and comments.
  case "$line" in
    '' | \#*) continue ;;
  esac

  # GitHub repo URL line. Trailing path segments (e.g. /tree/main) are dropped.
  if [[ "$line" =~ https://github\.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+) ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    url="https://github.com/$owner/$repo"
    if [ -z "$current" ]; then
      printf '!! URL outside any section, skipped: %s\n' "$url" >&2
      continue
    fi

    count=$((count + 1))
    dir_name="${repo}-${owner}"
    class_dir="$CLONES_DIR/$current"
    dest="$class_dir/$dir_name"
    mkdir -p "$class_dir"

    # Migrate legacy flat clone clones/{owner}-{repo} -> clones/{class}/{repo}-{owner}.
    legacy="$CLONES_DIR/${owner}-${repo}"
    if [ -d "$legacy/.git" ] && [ ! -e "$dest" ]; then
      printf '== Moving legacy %s -> %s\n' "$legacy" "$dest"
      if ! mv "$legacy" "$dest"; then
        printf '!! Move failed: %s\n' "$legacy" >&2
        failures=$((failures + 1))
        continue
      fi
    fi

    # Migrate old class naming clones/{class}/{owner}-{repo} -> {repo}-{owner}.
    old_class="$class_dir/${owner}-${repo}"
    if [ -d "$old_class/.git" ] && [ ! -e "$dest" ]; then
      printf '== Moving legacy %s -> %s\n' "$old_class" "$dest"
      if ! mv "$old_class" "$dest"; then
        printf '!! Move failed: %s\n' "$old_class" >&2
        failures=$((failures + 1))
        continue
      fi
    fi

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
  fi
done < "$SOURCES"

if [ "$count" -eq 0 ]; then
  printf 'No GitHub repos found in %s\n' "$SOURCES" >&2
  exit 1
fi

if [ "$failures" -gt 0 ]; then
  printf 'Done with %d error(s).\n' "$failures" >&2
  exit 1
fi

printf 'All %s repos are up to date in %s\n' "$count" "$CLONES_DIR"
