# Contract: iTerm2 Launch Adapter

## Dependency Discovery

- Locate iTerm2 by bundle identifier `com.googlecode.iterm2` through `NSWorkspace`.
- Do not assume `/Applications/iTerm.app`; a valid user-selected installation location is allowed.
- If no matching application is available, return `iTermNotInstalled` without opening another
  terminal application.

## Request

The adapter accepts exactly one `LaunchRequest` containing:

- A validated absolute directory file URL.
- The fixed iTerm2 bundle identifier.
- Activation enabled.

The adapter passes the directory URL to the modern asynchronous `NSWorkspace` open API with the
located iTerm2 application URL.

## Prohibited Behavior

- Do not construct or execute `cd`, `open`, or another shell command.
- Do not write text into an existing terminal session.
- Do not use iTerm2's deprecated AppleScript API or require its opt-in Python API.
- Do not substitute another terminal or another directory after an error.

## Lifecycle Outcomes

The end-to-end contract, verified on every available declared configuration, is:

| Initial iTerm2 state | Required result |
|----------------------|-----------------|
| Stopped | Launch iTerm2 and open a window/session at the target directory |
| Running with a usable window | Open a new tab in an available window at the target directory |
| Running without a usable window | Open a new usable window/session at the target directory |

`NSWorkspace` completion without an error is an adapter success, but compatibility validation MUST also
inspect the resulting session's working directory before recording an end-to-end pass.

## Error Mapping

| Condition | Result |
|-----------|--------|
| No app for `com.googlecode.iterm2` | `iTermNotInstalled` |
| macOS rejects or cannot complete the URL open request | `iTermOpenFailed` |
| Target disappears before handoff | `targetUnavailable` |
| Any uncategorized platform error | `unexpectedFailure` with user-safe description |

Errors may include platform diagnostics for developers, but user messages and persisted reports
MUST NOT include the literal target path.
