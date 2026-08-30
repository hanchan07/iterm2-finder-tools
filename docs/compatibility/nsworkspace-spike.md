# NSWorkspace Directory-URL Spike

Recorded: 2026-08-29

## Harness

`OpenITermTests/ITermLaunchContractTests.swift` contains a manual `NSWorkspace` directory-URL
harness. Its automated preflight confirms that the installed iTerm2 bundle can be found by
`com.googlecode.iterm2`; the actual open call is intentionally manual so each required iTerm2
lifecycle state can be controlled and its resulting working directory inspected.

## Required matrix status

| iTerm2 version | Stopped | Usable window | No usable window | Status |
| --- | --- | --- | --- | --- |
| 3.6.11 | Pass | Pass | Pass | verified |
| 3.7 prerelease | Not available | Not available | Not available | unverified |

### Usable-window evidence

On 2026-08-30, a one-shot `NSWorkspace.open(_:withApplicationAt:configuration:completionHandler:)`
request completed without error for a dedicated temporary directory. The operator-provided screenshot
shows an existing iTerm2 tab remained available and a new tab was created with the target directory in
its title and shell prompt. This verifies the **running with a usable window** outcome for iTerm2
3.6.11. The report intentionally omits the literal temporary path.

### Stopped-state evidence

On 2026-08-30, the operator first quit iTerm2. The same one-shot `NSWorkspace` request then
completed without error for a second dedicated temporary directory. The operator-provided screenshot
shows iTerm2 launched a fresh window and the target directory appeared in both its title and shell
prompt. This verifies the **stopped** outcome for iTerm2 3.6.11. The report intentionally omits the
literal temporary path.

### No-usable-window evidence

On 2026-08-30, the operator closed the last iTerm2 window while keeping the application running.
The one-shot `NSWorkspace` request completed without error for a third dedicated temporary directory.
The operator-provided screenshot shows iTerm2 created a new usable window and the target directory
appeared in both its title and shell prompt. This verifies the **running without a usable window**
outcome for iTerm2 3.6.11. The report intentionally omits the literal temporary path.

## T014 decision

The iTerm2 3.6.11 `NSWorkspace` directory-URL mechanism passed every required lifecycle state.
Production implementation may proceed using this mechanism. The result does not verify iTerm2 3.7
or macOS 27, which remain future matrix checks.

The iTerm2 3.7 prerelease application is not installed on this host and remains unverified. T014
proceeds with installed iTerm2 3.6.11; 3.7 validation is a future matrix task and cannot make a
compatibility claim until it is executed.
