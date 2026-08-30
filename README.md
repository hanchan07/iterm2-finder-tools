# iTerm2 Finder Tools

A native Apple-silicon Finder toolbar app and Finder Service that opens the current Finder folder in the installed iTerm2 application. It passes the folder as a file URL through macOS `NSWorkspace`; it does not construct shell commands or use iTerm2's deprecated AppleScript API.

## Requirements

- Apple-silicon Mac running macOS 26 or later
- Xcode 26 or later, with its license accepted (`sudo xcodebuild -license accept`)
- iTerm2 installed (identified by `com.googlecode.iterm2`)

## Build and use

```sh
./scripts/build.sh --configuration release --signing ad-hoc
./scripts/verify-artifact.sh 'build/Open iTerm.app'
```

The usable app bundle is [build/Open iTerm.app](build/Open%20iTerm.app). It can remain there; an installer is not required.

1. Open a Finder folder and drag the app bundle onto Finder's toolbar while holding Command.
2. Click it with a Finder folder active. macOS may ask to allow the app to control Finder.
3. macOS or iTerm2 may separately ask for access when the folder is in a protected location such as Desktop, Documents, Downloads, or a removable volume.

The Finder Service is registered when the app bundle launches. In Finder, select exactly one folder, then use **Finder → Services → Open iTerm**. Enable it in **System Settings → Keyboard → Keyboard Shortcuts → Services** if it is not shown immediately.

This is a personal-use, ad-hoc-signed build. macOS may require **Open Anyway** in Privacy & Security after its first launch.

## Tests

The app consumes the same `OpenITermCore` package exercised by the standalone test suite:

```sh
./scripts/test.sh
```

The optional iTerm lifecycle spike runs only when `OPEN_ITERM_SPIKE_DIRECTORY` names an existing directory. Normal test runs do not open a new iTerm session.

## Legacy artifacts

The root-level `Open iTerm.app`, `Open iTerm.workflow`, `application/`, `service/`, `build.py`, and AppleScript files are retained only as historical reference. They are not inputs to the Swift build. Use only the app produced in `build/`.

## Current compatibility

The current implementation is verified on Apple silicon, macOS 26.6, and iTerm2 3.6.11 for iTerm2's stopped, usable-window, and no-usable-window states. iTerm2 3.7 and macOS 27 remain unverified future compatibility checks.
