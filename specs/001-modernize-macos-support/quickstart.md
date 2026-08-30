# Quickstart: Validate Modern macOS Support

This guide is runnable after the implementation tasks create the Xcode project and scripts defined
by [plan.md](plan.md). It proves the feature end to end; it does not replace the detailed contracts.

## Prerequisites

- An Apple-silicon Mac running macOS Tahoe 26.6 or later.
- A second macOS 27 beta/GA test environment for macOS 27 claims.
- Xcode 26.6 or a compatible newer release, selected with `xcode-select`, with its license accepted.
- iTerm2 3.6.11 or later; use the current 3.7 prerelease while validating prerelease macOS 27.
- A clean macOS user account for first-run installation and permission validation.
- A trusted local source checkout. Apple Developer Program membership and distribution
  credentials are not required.

## 1. Verify the Toolchain

```bash
xcodebuild -version
swift --version
sw_vers
uname -m
```

Expected: the commands report the intended Xcode/Swift versions, exact macOS build, and host
architecture. If Xcode reports an unaccepted license, accept it outside this workflow before
continuing.

## 2. Run Automated Tests

```bash
xcodebuild test \
  -project OpenITerm.xcodeproj \
  -scheme OpenITerm \
  -destination 'platform=macOS'
```

Expected: target-resolution, Finder entry-point, iTerm launch-adapter, error, and path-corpus tests
all pass. Test fixtures cover spaces, quotes, shell metacharacters, Unicode, newlines, leading
hyphens, folder aliases, regular-file rejection, missing targets, empty input, and multiple
selections.

## 3. Build an arm64 Personal App

```bash
./scripts/build.sh --configuration release --signing ad-hoc
./scripts/verify-artifact.sh 'build/Open iTerm.app'
lipo -archs 'build/Open iTerm.app/Contents/MacOS/Open iTerm'
```

Expected: verification passes and `lipo` reports exactly `arm64`. Bundle metadata matches the
[local personal build contract](contracts/release-artifact.md), `codesign` reports an ad-hoc local
signature, and no network or broad file entitlement is present.

## 4. Install the Personal Build

1. Copy `build/Open iTerm.app` to a stable personal location such as `~/Applications` or
   `/Applications`.
2. Launch it once from Finder so macOS registers the application and its Service.
3. Command-drag the application into Finder's toolbar.
4. If **Open iTerm** is not enabled, open System Settings, find Services keyboard shortcuts, and
   enable it under Files and Folders.
5. Read each Automation prompt and allow Finder access only for this application.

If macOS identifies the personal build as coming from an unidentified developer, review the source
and use the supported **Open Anyway** control in System Settings > Privacy & Security. Never disable
Gatekeeper globally or remove quarantine metadata. If a build copied from another Mac remains
blocked, rebuild it from source on the target Mac.

Expected: the app appears in Finder's toolbar and **Open iTerm** appears for an applicable Finder
selection. No Rosetta, Accessibility, Full Disk Access, or network permission is requested.

## 5. Validate the Primary Journey

For both the toolbar and service entry points, run 20 trials for each applicable initial state:

1. iTerm2 stopped.
2. iTerm2 running with a usable terminal window.
3. iTerm2 running without a usable terminal window.

For each trial, record whether the resulting session appears within five seconds and whether its
working directory exactly matches the Finder directory. The expected lifecycle outcomes are in
[iterm-launch.md](contracts/iterm-launch.md).

Expected: 20/20 correct-directory results for every tested state and at least 19/20 results within
five seconds.

## 6. Validate the Path Corpus and Errors

Using temporary fixtures that contain no sensitive data, test folders representing:

- Spaces and leading hyphens.
- Single quotes, double quotes, semicolons, dollar signs, and backticks.
- Newline characters, non-Latin scripts, and emoji.
- A regular file, which the service MUST reject rather than opening its parent.
- A Finder alias to a folder, which succeeds, plus aliases to a file and an unresolved target,
  which fail.
- A removable or non-startup volume.
- Empty service input through the contract harness, two folders, a folder-plus-file mixed
  selection, a missing/disconnected target, no Finder window, missing iTerm2, and denied Automation
  permission.

Expected: every valid case opens the exact directory with no additional command or side effect.
Every invalid case produces an actionable failure and does not report success from another
directory. Evidence stores only path-category labels, never literal test paths.

## 7. Validate Local Build Integrity and Trust Status

```bash
./scripts/verify-artifact.sh 'build/Open iTerm.app'
file 'build/Open iTerm.app/Contents/MacOS/Open iTerm'
lipo -archs 'build/Open iTerm.app/Contents/MacOS/Open iTerm'
codesign --verify --deep --strict --verbose=2 'build/Open iTerm.app'
codesign --display --entitlements - --verbose=4 'build/Open iTerm.app'
```

Expected: the executable is arm64 only, code integrity is valid, signing is ad-hoc/Sign to Run
Locally with no Developer ID identity, and the bundle carries only the expected Apple Events
entitlement. Developer ID, notarization, stapling, and `spctl` acceptance are deliberately not
required. Record whether Automation permission is requested again after a rebuild.

## 8. Record Matrix Evidence

Create one report per source revision under `docs/compatibility/` and validate it against
[compatibility-report.schema.json](contracts/compatibility-report.schema.json). Each declared
configuration records its source revision, Xcode version, local build origin, and ad-hoc signing
mode, then receives `pass`, `fail`, or `unverified` results for both entry points, all three iTerm2
states, selection categories, path categories, installation, permissions, removal, and artifact
checks.

Do not publish a configuration as supported if its report contains a completion-blocking failure or
if the configuration was not tested. Prerelease macOS results remain `provisional` until repeated
against the generally available build.
