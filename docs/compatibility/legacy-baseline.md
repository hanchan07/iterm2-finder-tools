# Legacy Baseline

Recorded: 2026-08-29 on an arm64 Mac running macOS 26.6.2.

## Static inspection

- `Open iTerm.app/Contents/MacOS/Application Stub` is an x86_64-only Mach-O executable.
- The legacy bundle is unsigned.
- Its metadata identifies an Automator application stub built with the macOS 10.11/Xcode 7.2-era
  toolchain.
- The Finder Service is an Automator workflow rather than a separately embedded executable.
- Both legacy workflows invoke iTerm2 through AppleScript and type a `cd` command into a session.

## Current interactive result

Finder-toolbar and Service invocation were not exercised from this non-interactive build session,
so no current runtime result is claimed. The static x86_64-only toolbar wrapper is incompatible
with the declared native-arm64 requirement and requires Rosetta on Apple silicon.

## Reproduction reference

1. Inspect the toolbar binary with `file 'Open iTerm.app/Contents/MacOS/Application Stub'`.
2. Inspect the bundle signature with `codesign -dvv 'Open iTerm.app'`.
3. Command-drag the legacy app into Finder's toolbar and invoke it from a Finder window.
4. Invoke **Open iTerm** through Finder Services with one selected folder.

Interactive results must be added during migration validation; this record does not infer them.
