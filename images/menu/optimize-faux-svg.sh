#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------
# Config (override via env vars)
# -----------------------------------------
JPG_QUALITY="${JPG_QUALITY:-82}"      # ~web sweet spot
WEBP_QUALITY="${WEBP_QUALITY:-82}"    # if we need to transcode to webp temporarily
PNG_QUALITY="${PNG_QUALITY:-90}"      # IM's PNG compression effort (0-100)
GIF_DITHER="${GIF_DITHER:-FloydSteinberg}"  # or None
AVIF_QUALITY="${AVIF_QUALITY:-28}"    # IM AVIF: lower ~ smaller (if supported)

# -----------------------------------------
# Need these:
# -----------------------------------------
need() { command -v "$1" >/dev/null 2>&1; }
if ! need file; then
  echo "Error: 'file' is required (dnf install file)" >&2
  exit 1
fi
if ! need magick && ! need convert; then
  echo "Error: ImageMagick is required (dnf install ImageMagick)" >&2
  exit 1
fi

IM_BIN="$(command -v magick || command -v convert)"

# -----------------------------------------
# Helpers
# -----------------------------------------
is_image() {
  case "$1" in
    image/jpeg|image/png|image/webp|image/gif|image/avif|image/heif|image/heic) return 0 ;;
    *) return 1 ;;
  esac
}

backup_once() {
  local f="$1"
  # Only create backup once (any .bak.* present means we’ve backed up before)
  if ! ls "${f}.bak."* >/dev/null 2>&1; then
    local stamp; stamp="$(date +%Y%m%d-%H%M%S)"
    cp -p -- "$f" "$f.bak.$stamp"
    echo "  → Backup created: $(basename "$f.bak.$stamp")"
  fi
}

replace_if_smaller() {
  local src="$1" tmp="$2"
  if [ ! -s "$tmp" ]; then
    echo "  → No output produced; keeping original."
    rm -f -- "$tmp"
    return
  fi
  local o n
  o=$(stat -c%s -- "$src")
  n=$(stat -c%s -- "$tmp")
  if [ "$n" -lt "$o" ]; then
    touch -r "$src" "$tmp"
    mv -f -- "$tmp" "$src"
    echo "  → Optimized: $o → $n bytes"
  else
    echo "  → Not smaller ($n ≥ $o); keeping original."
    rm -f -- "$tmp"
  fi
}

has_alpha() {
  # returns 0 if alpha channel is present
  "$IM_BIN" identify -format "%[channels]" "$1" 2>/dev/null | grep -qi 'a'
}

# -----------------------------------------
# Optimizers (ImageMagick-only)
# -----------------------------------------
optimize_jpeg() {
  # Progressive JPEG, strip metadata, 4:2:0 subsampling
  "$IM_BIN" "$1" -strip -sampling-factor 4:2:0 -interlace Plane -quality "$JPG_QUALITY" "$2"
}

optimize_png() {
  # Strip metadata; use zlib effort. (IM's -quality on PNG controls zlib effort)
  "$IM_BIN" "$1" -strip -define png:compression-level=9 -quality "$PNG_QUALITY" "$2"
}

optimize_webp() {
  if has_alpha "$1"; then
    "$IM_BIN" "$1" -strip -quality "$WEBP_QUALITY" "$2"
  else
    "$IM_BIN" "$1" -strip -quality "$WEBP_QUALITY" "$2"
  fi
}

optimize_gif() {
  # Dither & optimize frames if animated; strip metadata
  "$IM_BIN" "$1" -strip -coalesce -dither "$GIF_DITHER" -layers Optimize "$2"
}

optimize_avif() {
  # Works only if your IM build supports AVIF
  "$IM_BIN" "$1" -strip -quality "$AVIF_QUALITY" "$2" || return 1
}

optimize_heif_like() {
  # If IM can read HEIC/HEIF, we’ll write back in a high-efficiency form that IM supports best.
  # Prefer AVIF if supported, else fall back to high-quality JPEG.
  local tmp_avif; tmp_avif="$(mktemp --suffix=.avif)"
  if optimize_avif "$1" "$tmp_avif"; then
    mv -f -- "$tmp_avif" "$2"
  else
    rm -f -- "$tmp_avif"
    optimize_jpeg "$1" "$2"
  fi
}

optimize_unknown_generic() {
  # Fallback: transcode to a decent progressive JPEG
  optimize_jpeg "$1" "$2"
}

# -----------------------------------------
# Main
# -----------------------------------------
DIR="${1:-.}"
shopt -s nullglob

mapfile -t files < <(find "$DIR" -maxdepth 1 -type f -name '*.svg' -print0 | xargs -0 -I{} bash -c 'printf "%s\n" "$1"' _ {})

if [ ${#files[@]} -eq 0 ]; then
  echo "No *.svg files found in: $DIR"
  exit 0
fi

echo "Scanning ${#files[@]} files in: $DIR"
for f in "${files[@]}"; do
  echo "• $(basename "$f")"
  mime="$(file -b --mime-type -- "$f" || echo unknown)"

  if [[ "$mime" == "image/svg+xml" ]]; then
    echo "  → Real SVG detected; skipping."
    continue
  fi
  if ! is_image "$mime"; then
    echo "  → Not a supported raster type ($mime); skipping."
    continue
  fi

  backup_once "$f"
  tmp="$(mktemp)"

  case "$mime" in
    image/jpeg) optimize_jpeg "$f" "$tmp" ;;
    image/png)  optimize_png  "$f" "$tmp" ;;
    image/webp) optimize_webp "$f" "$tmp" ;;
    image/gif)  optimize_gif  "$f" "$tmp" ;;
    image/avif) optimize_avif "$f" "$tmp" || optimize_unknown_generic "$f" "$tmp" ;;
    image/heif|image/heic) optimize_heif_like "$f" "$tmp" ;;
    *) optimize_unknown_generic "$f" "$tmp" ;;
  esac

  replace_if_smaller "$f" "$tmp"
done

echo "Done."
