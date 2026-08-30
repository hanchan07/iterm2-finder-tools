#!/bin/zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
configuration="Release"

usage() {
  print -u2 "Usage: $0 [--configuration Debug|Release] [--signing ad-hoc]"
}

while (( $# )); do
  case "$1" in
    --configuration)
      (( $# >= 2 )) || { usage; exit 64; }
      case "$2" in
        Debug|debug) configuration="Debug" ;;
        Release|release) configuration="Release" ;;
        *) usage; exit 64 ;;
      esac
      shift 2
      ;;
    --signing)
      (( $# >= 2 )) || { usage; exit 64; }
      [ "$2" = "ad-hoc" ] || { print -u2 "Only --signing ad-hoc is supported"; exit 64; }
      shift 2
      ;;
    *) usage; exit 64 ;;
  esac
done

xcodebuild \
  -project "$repo_root/OpenITerm.xcodeproj" \
  -scheme "Open iTerm" \
  -configuration "$configuration" \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$repo_root/DerivedData" \
  -clonedSourcePackagesDirPath "$repo_root/DerivedData/SourcePackages" \
  -packageCachePath "$repo_root/DerivedData/PackageCache" \
  ARCHS=arm64 \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM= \
  build

built_app="$repo_root/DerivedData/Build/Products/$configuration/Open iTerm.app"
output_app="$repo_root/build/Open iTerm.app"

[ -d "$built_app" ] || { print -u2 "Missing built app: $built_app"; exit 1; }
[ "$output_app" = "$repo_root/build/Open iTerm.app" ] || { print -u2 "Unexpected output path"; exit 1; }
mkdir -p "$repo_root/build"
rm -rf "$output_app"
/usr/bin/ditto "$built_app" "$output_app"
