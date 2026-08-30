#!/bin/zsh
set -euo pipefail

app_path="${1:-build/Open iTerm.app}"
executable="$app_path/Contents/MacOS/Open iTerm"
info_plist="$app_path/Contents/Info.plist"
temp_entitlements="$(mktemp /private/tmp/open-iterm-entitlements.XXXXXX)"
trap 'rm -f "$temp_entitlements"' EXIT

[ -d "$app_path" ] || { print -u2 "Missing app bundle: $app_path"; exit 1; }
[ -x "$executable" ] || { print -u2 "Missing executable: $executable"; exit 1; }
[ "$(plutil -extract CFBundleIdentifier raw -o - "$info_plist")" = "com.peterldowns.OpeniTerm" ]
[ "$(plutil -extract LSUIElement raw -o - "$info_plist")" = "true" ]
[ "$(plutil -extract LSMinimumSystemVersion raw -o - "$info_plist")" = "26.0" ]
[ "$(lipo -archs "$executable")" = "arm64" ]
codesign --verify --strict --verbose=2 "$app_path"
codesign --display --entitlements :- "$app_path" 2>&1 | sed -n '/<?xml/,/<\/plist>/p' > "$temp_entitlements"
[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.automation.apple-events' "$temp_entitlements")" = "true" ]
[ "$(plutil -p "$temp_entitlements" | rg -c ' => ')" = "1" ] || {
  print -u2 "Expected exactly one entitlement"
  exit 1
}
print "Verified $app_path: arm64, ad-hoc signed, automation Apple Events entitlement only"
