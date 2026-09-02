#!/bin/zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
app_path="$repo_root/build/Open iTerm.app"
release_directory="$repo_root/releases"
temporary_directory="$(mktemp -d /private/tmp/open-iterm-release.XXXXXX)"

cleanup() {
  rm -rf "$temporary_directory"
}
trap cleanup EXIT

"$repo_root/scripts/build.sh" --configuration release --signing ad-hoc
"$repo_root/scripts/verify-artifact.sh" "$app_path"

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Contents/Info.plist")"
archive_name="Open-iTerm-${version}-macos-arm64.zip"
versioned_archive="$release_directory/$archive_name"
latest_archive="$release_directory/Open-iTerm-macos-arm64.zip"
temporary_archive="$temporary_directory/$archive_name"

mkdir -p "$release_directory"
/usr/bin/ditto -c -k --keepParent "$app_path" "$temporary_archive"
/usr/bin/ditto "$temporary_archive" "$versioned_archive"
/usr/bin/ditto "$temporary_archive" "$latest_archive"

(
  cd "$release_directory"
  shasum -a 256 "$archive_name" > "$archive_name.sha256"
  shasum -a 256 "$(basename "$latest_archive")" > "$(basename "$latest_archive").sha256"
)

print "Created $versioned_archive"
print "Updated $latest_archive"
