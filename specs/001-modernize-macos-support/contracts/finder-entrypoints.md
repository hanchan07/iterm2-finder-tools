# Contract: Finder Entry Points

## Toolbar Invocation

**Trigger**: The user clicks `Open iTerm.app` after Command-dragging it into the Finder toolbar.

**Input**: No document payload.

**Context resolution**:

1. Confirm Finder is available and has a front file-viewer window.
2. Request only that window's target directory URL through `FinderLocationProvider`.
3. Resolve the URL through `DirectoryTargetResolver`.
4. Submit one `LaunchRequest`.

**Success**: iTerm2 is activated with a session whose working directory is the exact front Finder
directory.

**Failures**: No Finder window, denied Automation permission, unavailable target, missing iTerm2,
or failed open request produces an actionable alert and a failed exit. The application MUST NOT
fall back silently to the home directory or another working directory.

## Finder Service Invocation

**Registration**: The app advertises one `NSServices` item named **Open iTerm** with
`NSSendFileTypes = [public.item]`, a Finder-only `NSRequiredContext` application identifier, and
one service message. The broad file-system type preserves legacy visibility; the handler, not the
metadata, enforces the single-folder contract.

**Input**: Finder supplies file URLs through the service pasteboard.

**Resolution**:

- Exactly one selected existing directory resolves to itself.
- A Finder alias resolves before validation and succeeds only when its target is one existing
  directory.
- A regular file, alias to a file, zero items, multiple items, non-file URL, missing target, or
  unresolvable alias fails before iTerm2 is located or launched.
- The resolver never selects the first item, derives a file's parent directory, or chooses a
  fallback directory.

**Success**: The service submits one `LaunchRequest` and reports no pasteboard output.

**Failure**: The service returns a localized error stating that exactly one folder is required
and, where Finder permits, presents the same actionable alert as toolbar invocation. Finder may
suppress the Service when no item is selected, but the handler still rejects an empty pasteboard
when invoked through a contract harness or another supported caller.

## Shared Privacy and Safety Rules

- Input URLs remain typed file URLs and MUST NOT be interpolated into a shell command.
- The app MAY inspect file metadata needed to determine existence and directory status; it MUST
  NOT read file contents.
- Literal paths MUST NOT be logged, persisted, transmitted, or written into compatibility reports.
- The app MUST request Finder Apple Events only for toolbar invocation; service input requires no
  additional Finder query.
- The app exits after the launch request or error is delivered.
