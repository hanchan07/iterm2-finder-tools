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

### Add Open iTerm to Finder

1. Keep `Open iTerm.app` in a permanent location. For a downloaded release, move it from Downloads to Applications or another folder you will not later delete or rename.
2. Open any Finder window. Hold Command and drag `Open iTerm.app` onto Finder's toolbar.
3. Navigate to the folder you want to open in iTerm2, then click the new toolbar icon. macOS may ask to allow Open iTerm to control Finder.
4. macOS or iTerm2 may separately ask for access when the folder is in a protected location such as Desktop, Documents, Downloads, or a removable volume.

The Finder Service is registered when the app bundle launches. In Finder, select exactly one folder, then use **Finder → Services → Open iTerm**. Enable it in **System Settings → Keyboard → Keyboard Shortcuts → Services** if it is not shown immediately.

### First launch of a downloaded build

This is a personal-use, ad-hoc-signed build. macOS may show “Apple could not verify ‘Open iTerm’ is free of malware” the first time a browser-downloaded copy is launched.

1. Click **Done** in that alert. Do not click **Move to Trash**.
2. Immediately open **System Settings → Privacy & Security**, scroll to **Security**, and click **Open Anyway** for Open iTerm.
3. Confirm **Open** and enter your Mac password if asked. The exception is then saved for future launches.

The **Open Anyway** control is normally available for about one hour after the blocked launch attempt. If it is absent, the Mac may be managed to prohibit overriding Gatekeeper. Only override this warning for a copy you obtained from a source you trust.

## Download the current build

Download [Open iTerm for Apple silicon](releases/Open-iTerm-macos-arm64.zip) and its [SHA-256 checksum](releases/Open-iTerm-macos-arm64.zip.sha256), unzip it, then follow [Add Open iTerm to Finder](#add-open-iterm-to-finder) and [First launch of a downloaded build](#first-launch-of-a-downloaded-build).

To verify the download from a local clone:

```sh
(cd releases && shasum -a 256 -c Open-iTerm-macos-arm64.zip.sha256)
```

To publish an updated app bundle after changing the source or its version, run:

```sh
./scripts/package-release.sh
```

This rebuilds and verifies the app, then updates `releases/Open-iTerm-macos-arm64.zip`. When the version is newer than the current latest build, the packager first preserves that previous latest build as a versioned historical archive such as `releases/Open-iTerm-1.5.0-macos-arm64.zip`. Commit those archives with the source change so the repository's download always matches its code.

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
