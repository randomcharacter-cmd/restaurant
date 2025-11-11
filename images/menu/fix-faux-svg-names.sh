#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Rename misnamed images to their actual extension and log it.
# ------------------------------------------------------------
# Usage:
#   ./fix-faux-svg-names.sh                # process *.svg in .
#   ./fix-faux-svg-names.sh /path/to/dir   # process *.svg in given dir
#   ./fix-faux-svg-names.sh --all          # process all files in .
#   ./fix-faux-svg-names.sh --all DIR      # process all files in DIR
#   DRY RUN:
#   ./fix-faux-svg-names.sh --dry-run
#
# Log:
#   Creates CSV: rename-log-YYYYmmdd-HHMMSS.csv in the target dir.
#
# Requirements: `file` utility (dnf install file)
# ------------------------------------------------------------

need() { command -v "$1" >/dev/null 2>&1; }

if ! need file; then
  echo "Error: 'file' is required. Install it (e.g., 'sudo dnf install -y file')." >&2
  exit 1
fi

ALL_FILES=false
DRY_RUN=false
TARGET_DIR="."

# Parse flags/args
for arg in "$@"; do
  case "$arg" in
    --all) ALL_FILES=true ;;
    --dry-run) DRY_RUN=true ;;
    *) TARGET_DIR="$arg" ;;
  esac
done

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: directory not found: $TARGET_DIR" >&2
  exit 1
fi

timestamp() { date +%Y-%m-%dT%H:%M:%S; }

# Map MIME → extension
ext_from_mime() {
  case "$1" in
    image/jpeg) echo "jpg" ;;
    image/png) echo "png" ;;
    image/webp) echo "webp" ;;
    image/gif) echo "gif" ;;
    image/avif) echo "avif" ;;
    image/heic|image/heif) echo "heic" ;;
    image/tiff) echo "tif" ;;
    image/bmp) echo "bmp" ;;
    image/svg+xml) echo "svg" ;;   # real svg → skip
    application/pdf) echo "pdf" ;; # sometimes misfiled visuals
    *) echo "" ;;
  esac
}

# Create a non-colliding path by appending -1, -2, ...
unique_path() {
  local path="$1"
  if [ ! -e "$path" ]; then
    printf "%s" "$path"
    return 0
  fi
  local dir base ext n
  dir="$(dirname -- "$path")"
  base="$(basename -- "$path")"
  ext="" ; n=1
  if [[ "$base" == *.* ]]; then
    ext=".${base##*.}"
    base="${base%.*}"
  fi
  while :; do
    if [ ! -e "$dir/${base}-$n$ext" ]; then
      printf "%s" "$dir/${base}-$n$ext"
      return 0
    fi
    n=$((n+1))
  done
}

# Gather candidate files
shopt -s nullglob
if $ALL_FILES; then
  # Every regular file (non-recursive)
  mapfile -d '' -t FILES < <(find "$TARGET_DIR" -maxdepth 1 -type f -print0)
else
  # Only .svg files (non-recursive)
  mapfile -d '' -t FILES < <(find "$TARGET_DIR" -maxdepth 1 -type f -name '*.svg' -print0)
fi

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "No matching files found in: $TARGET_DIR"
  exit 0
fi

LOG_PATH="$TARGET_DIR/rename-log-$(date +%Y%m%d-%H%M%S).csv"
echo "timestamp,old_path,new_path,mime" > "$LOG_PATH"

echo "Processing ${#FILES[@]} file(s) in: $TARGET_DIR"
$DRY_RUN && echo "(DRY-RUN: no changes will be made)"
echo "Logging to: $LOG_PATH"

for f in "${FILES[@]}"; do
  # Get MIME
  mime="$(file -b --mime-type -- "$f" || echo unknown)"
  want_ext="$(ext_from_mime "$mime")"
  base="$(basename -- "$f")"
  dir="$(dirname -- "$f")"

  # Determine current extension (lowercased, without dot)
  cur_ext=""
  if [[ "$base" == *.* ]]; then
    cur_ext="${base##*.}"
    cur_ext="${cur_ext,,}"
  fi

  # Decide action
  if [[ "$mime" == "image/svg+xml" ]]; then
    echo "• $(basename -- "$f"): real SVG → skip"
    echo "$(timestamp),$f,$f,$mime" >> "$LOG_PATH"
    continue
  fi

  if [[ -z "$want_ext" ]]; then
    echo "• $(basename -- "$f"): unknown/unsupported MIME ($mime) → skip"
    echo "$(timestamp),$f,$f,$mime" >> "$LOG_PATH"
    continue
  fi

  # If extension already matches, skip
  if [[ "$cur_ext" == "$want_ext" ]]; then
    echo "• $(basename -- "$f"): already .${want_ext} → skip"
    echo "$(timestamp),$f,$f,$mime" >> "$LOG_PATH"
    continue
  fi

  # Build new path with correct extension
  stem="${base%.*}"
  new_path_guess="$dir/${stem}.${want_ext}"
  new_path="$(unique_path "$new_path_guess")"

  if $DRY_RUN; then
    echo "• $base → $(basename -- "$new_path")  [$mime]"
    echo "$(timestamp),$f,$new_path,$mime" >> "$LOG_PATH"
  else
    mv -- "$f" "$new_path"
    echo "• $base → $(basename -- "$new_path")  [$mime]"
    echo "$(timestamp),$f,$new_path,$mime" >> "$LOG_PATH"
  fi
done

echo "Done."
