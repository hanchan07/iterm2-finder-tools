#!/bin/zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

swift test --package-path "$repo_root"

xcodebuild test \
  -project "$repo_root/OpenITerm.xcodeproj" \
  -scheme "Open iTerm" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$repo_root/DerivedData" \
  -clonedSourcePackagesDirPath "$repo_root/DerivedData/SourcePackages" \
  -packageCachePath "$repo_root/DerivedData/PackageCache"
