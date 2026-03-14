#!/usr/bin/env bash
set -euo pipefail

# Fixes missing AdMob/UMP framework dSYMs in an .xcarchive before upload.
# Usage:
#   scripts/fix_archive_google_dsyms.sh
#   scripts/fix_archive_google_dsyms.sh "/path/to/MyApp.xcarchive"

archive_path="${1:-}"
archives_root="$HOME/Library/Developer/Xcode/Archives"

if [[ -z "$archive_path" ]]; then
  archive_path="$(find "$archives_root" -name "*.xcarchive" -type d -print0 | xargs -0 ls -td | head -n 1)"
fi

if [[ -z "${archive_path:-}" || ! -d "$archive_path" ]]; then
  echo "error: .xcarchive not found" >&2
  exit 1
fi

app_path="$(find "$archive_path/Products/Applications" -maxdepth 1 -name "*.app" | head -n 1)"
if [[ -z "${app_path:-}" || ! -d "$app_path" ]]; then
  echo "error: app bundle not found in archive: $archive_path" >&2
  exit 1
fi

dsyms_dir="$archive_path/dSYMs"
mkdir -p "$dsyms_dir"

frameworks=("GoogleMobileAds" "UserMessagingPlatform")

echo "Archive: $archive_path"
echo "App: $app_path"

for framework in "${frameworks[@]}"; do
  binary="$app_path/Frameworks/$framework.framework/$framework"
  out_dsym="$dsyms_dir/$framework.framework.dSYM"

  if [[ ! -f "$binary" ]]; then
    echo "skip: $framework binary not found in app frameworks"
    continue
  fi

  echo ""
  echo "Generating dSYM for $framework..."
  xcrun dsymutil "$binary" -o "$out_dsym"

  echo "Binary UUID:"
  xcrun dwarfdump --uuid "$binary"
  echo "dSYM UUID:"
  xcrun dwarfdump --uuid "$out_dsym/Contents/Resources/DWARF/$framework"
done

echo ""
echo "Archive dSYMs now contain:"
find "$dsyms_dir" -maxdepth 2 -type d -name "*.dSYM" -print | sort

