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
latest_archive="$release_directory/Open-iTerm-macos-arm64.zip"
temporary_archive="$temporary_directory/Open-iTerm-macos-arm64.zip"

mkdir -p "$release_directory"

# Preserve the previous latest build as a historical download only when a newer
# version replaces it. The first/current release needs only the stable latest ZIP.
if [ -f "$latest_archive" ]; then
  previous_release_directory="$temporary_directory/previous-release"
  previous_app="$previous_release_directory/Open iTerm.app"
  mkdir -p "$previous_release_directory"
  /usr/bin/ditto -x -k "$latest_archive" "$previous_release_directory"
  [ -d "$previous_app" ] || { print -u2 "Latest archive does not contain Open iTerm.app"; exit 1; }

  previous_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$previous_app/Contents/Info.plist")"
  if [ "$previous_version" != "$version" ]; then
    historical_archive="$release_directory/Open-iTerm-${previous_version}-macos-arm64.zip"
    if [ ! -f "$historical_archive" ]; then
      /usr/bin/ditto "$latest_archive" "$historical_archive"
      (
        cd "$release_directory"
        shasum -a 256 "$(basename "$historical_archive")" > "$(basename "$historical_archive").sha256"
      )
      print "Preserved $historical_archive"
    fi
  fi
fi

/usr/bin/ditto -c -k --keepParent "$app_path" "$temporary_archive"
/usr/bin/ditto "$temporary_archive" "$latest_archive"

(
  cd "$release_directory"
  shasum -a 256 "$(basename "$latest_archive")" > "$(basename "$latest_archive").sha256"
)

print "Updated $latest_archive"
