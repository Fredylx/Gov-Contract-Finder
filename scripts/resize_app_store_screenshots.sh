#!/usr/bin/env bash
set -euo pipefail

# Resize screenshots to App Store accepted iPhone portrait sizes.
# Defaults to 6.7" size: 1284x2778.
#
# Usage:
#   scripts/resize_app_store_screenshots.sh /path/to/input_folder
#   scripts/resize_app_store_screenshots.sh /path/to/input_folder /path/to/output_folder
#   TARGET=1242x2688 scripts/resize_app_store_screenshots.sh /path/to/input_folder

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <input_folder> [output_folder]"
  exit 1
fi

input_dir="$1"
output_dir="${2:-$input_dir/AppStoreReady}"
target="${TARGET:-1284x2778}"

case "$target" in
  1242x2688|1284x2778|2688x1242|2778x1284) ;;
  *)
    echo "Unsupported TARGET=$target"
    echo "Supported: 1242x2688, 1284x2778, 2688x1242, 2778x1284"
    exit 1
    ;;
esac

if [[ ! -d "$input_dir" ]]; then
  echo "Input folder not found: $input_dir"
  exit 1
fi

mkdir -p "$output_dir"

target_w="${target%x*}"
target_h="${target#*x}"

processed=0
ok=0
failed=0

while IFS= read -r -d '' file; do
  processed=$((processed + 1))
  base="$(basename "$file")"
  name="${base%.*}"
  out="$output_dir/${name}_${target}.png"

  cp "$file" "$out"
  if ! sips --resampleHeightWidth "$target_h" "$target_w" "$out" >/dev/null 2>&1; then
    echo "FAIL resize: $file"
    rm -f "$out"
    failed=$((failed + 1))
    continue
  fi

  dims="$(sips -g pixelWidth -g pixelHeight "$out" 2>/dev/null | awk '/pixelWidth:/{w=$2}/pixelHeight:/{h=$2}END{print w "x" h}')"
  if [[ "$dims" == "$target" ]]; then
    ok=$((ok + 1))
    echo "OK  $dims  $out"
  else
    echo "FAIL size($dims): $file"
    failed=$((failed + 1))
  fi
done < <(find "$input_dir" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.heic" \) -print0)

echo "---"
echo "Input:  $input_dir"
echo "Output: $output_dir"
echo "Target: $target"
echo "Processed: $processed, OK: $ok, Failed: $failed"
echo "Done."
