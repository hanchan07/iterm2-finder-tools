# Research: Modernize macOS Support

## Scope and Verified Baseline

Research covered Finder integration, iTerm2 launch behavior, Apple-silicon packaging, privacy,
distribution, and validation. Local inspection on 2026-08-29 established:

- The host is an arm64 Mac running macOS 26.6.2.
- Xcode 26.6 contains Apple Swift 6.3.3, although its license is not yet accepted on this host.
- Installed iTerm2 3.6.11 is universal, supports macOS 12.4 or later, and declares
  `public.folder` as an openable document type.
- The current iTerm2 3.7 prerelease observed during planning is 3.7.0beta11 and requires macOS 13
  or later; the declared macOS 26/27 matrix exceeds that minimum.
- The checked-in `Open iTerm.app` executable is unsigned and x86_64-only.
- Both checked-in products embed Automator 2.6 workflows; the application depends on an old
  `Application Stub` binary.

Runtime behavior on macOS 27 remains unverified until the implementation is exercised on current
beta hardware. The plan treats beta results as provisional rather than claiming compatibility.

## Decision 1: One Native AppKit Bundle Provides Both Entry Points

**Decision**: Replace both Automator products with one Swift/AppKit accessory application. Users
Command-drag the app into Finder's toolbar. The same bundle advertises an `NSServices` provider
named **Open iTerm** for Finder file-system selections. Its metadata retains Finder-only
`NSRequiredContext` and `NSSendFileTypes = [public.item]`; the handler enforces exactly one folder
because Services metadata cannot constrain input cardinality. Set `LSUIElement` so normal
invocations do not leave a Dock icon or persistent UI process.

**Rationale**: One native arm64 executable removes the x86-only stub, keeps the existing user
journeys on the explicitly declared Apple-silicon-only matrix, shares all resolution and launch
logic, and avoids a second extension binary.

**Alternatives considered**:

- **Keep Automator**: macOS 26 still documents Automator Quick Actions, but the existing toolbar
  application is architecture-bound and Apple documents migration of workflows to Shortcuts.
  No forward-support guarantee for Automator on macOS 27 was found.
- **Finder Sync extension**: It offers toolbar and contextual UI, but Apple scopes Finder Sync to
  file-synchronization products and monitored folders. Registering broad folders would exceed this
  utility's purpose and permission needs.
- **Action extension**: It supports Finder Quick Actions but adds a sandboxed extension target,
  requires user enablement, and does not replace the draggable toolbar app.
- **Shortcuts/App Intents**: Useful as a user-managed fallback, but not a self-contained replacement
  for both distributed entry points; App Shortcuts are not supported on macOS.

Sources: [Finder toolbar customization](https://support.apple.com/guide/mac-help/customize-the-finder-toolbar-on-mac-mchlp3011/mac),
[`NSServices`](https://developer.apple.com/documentation/bundleresources/information-property-list/nsservices),
[Finder Sync](https://developer.apple.com/documentation/FinderSync), and
[Finder Action extensions](https://developer.apple.com/documentation/appkit/add-functionality-to-finder-with-action-extensions).

## Decision 2: Use Finder Apple Events Only for Toolbar Context

**Decision**: Implement a small `FinderLocationProvider` using Apple's ScriptingBridge framework
and a checked-in generated Finder interface. It retrieves only the front Finder window's target
URL. Service invocations bypass Apple Events and consume the Finder-provided file URL directly.

**Rationale**: A toolbar-launched app receives no selected-directory payload. ScriptingBridge is a
current system framework for sending Apple Events to scriptable apps and avoids embedding or
executing arbitrary script text. Isolating it behind a protocol keeps unit tests deterministic.

**Alternatives considered**:

- **Accessibility inspection**: Requires broader permission and UI-dependent behavior.
- **Shelling out to `osascript`**: Adds process and quoting complexity without reducing permission
  requirements.
- **Finder Sync**: Provides direct target URLs but is not intended for general Finder modification.

The locally built app includes `NSAppleEventsUsageDescription` and only the
`com.apple.security.automation.apple-events` entitlement. No Accessibility entitlement or network
entitlement is added.

Sources: [ScriptingBridge](https://developer.apple.com/documentation/scriptingbridge),
[Apple Events entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.automation.apple-events),
and [`NSAppleEventsUsageDescription`](https://developer.apple.com/documentation/bundleresources/information-property-list/nsappleeventsusagedescription).

## Decision 3: Pass a Directory URL to iTerm2 Through NSWorkspace

**Decision**: Locate iTerm2 by bundle identifier `com.googlecode.iterm2` and call the modern
`NSWorkspace` URL-opening API with the resolved directory file URL. Do not create a `cd` command,
write text into a terminal session, or invoke iTerm2's AppleScript/Python automation APIs.

**Rationale**: Installed iTerm2 3.6.11 declares `public.folder` support. Passing a typed file URL
keeps path data out of a shell language and lets Launch Services start or reuse iTerm2. Lifecycle
behavior remains a required integration test across stopped, windowed, and no-usable-window
states.

**Implementation gate**: This repository inspection verifies the declared folder-document
contract but does not verify the resulting tab/window lifecycle behavior. The first implementation
spike MUST exercise installed iTerm2 3.6.11. iTerm2 3.7 is a future compatibility matrix check and
is explicitly unverified until its application bundle is available. If any required 3.6.11 state
fails, implementation stops and this plan is amended before considering the iTerm2 Python API. The
deprecated AppleScript interface is not an automatic fallback.

**Alternatives considered**:

- **iTerm2 AppleScript**: iTerm2 explicitly labels it deprecated and maintenance-only.
- **iTerm2 Python API**: It is the recommended rich automation API, but it is disabled by default
  and external clients still require an AppleScript-derived authentication cookie. That creates
  extra setup and permissions for a one-action launcher.
- **Launching a shell command**: Reintroduces command-injection and escaping risk.

Sources: [`NSWorkspace`](https://developer.apple.com/documentation/AppKit/NSWorkspace),
[iTerm2 AppleScript deprecation](https://iterm2.com/3.4/documentation-scripting.html), and
[iTerm2 Python API security](https://iterm2.com/python-api-auth.html).

## Decision 4: Resolve Exactly One Directory Without Shell Conversion

**Decision**: Normalize each invocation to one absolute directory file URL. A toolbar invocation
uses the front Finder window's directory. A service invocation succeeds only for exactly one
selected folder; a resolvable Finder alias is accepted only when its target is one folder. Regular
files, empty input, multiple items, missing targets, unresolved aliases, and unsupported URLs fail
with a user-visible error. The application never converts a URL into executable text.

**Rationale**: This reproduces the legacy workflow's successful single-folder behavior while
turning its opaque coercion failures into actionable errors. It is deterministic and independently
testable with a fixed corpus.

**Alternatives considered**:

- **Use the first item from multiple selections**: Silent and surprising.
- **Use a common parent for multiple items**: Ambiguous when items span locations and different
  from the explicit single-context contract.
- **Resolve a regular file to its parent**: More permissive than the clarified compatibility
  contract and changes the legacy successful-input boundary.
- **Always fall back to the home directory**: Can report success at the wrong location.

## Decision 5: Use Xcode With an arm64 Local-Build Configuration

**Decision**: Create one Xcode project with an app target and test target, Swift 6 language mode,
macOS 26.0 deployment target, and `ARCHS=arm64`. Configure Team None and Xcode's **Sign to Run
Locally** mode, producing an ad-hoc-signed personal build. Use AppKit/Foundation only and no
package dependencies.

**Rationale**: The specification deliberately limits the modernization to Apple silicon and names
macOS 26/27 as the supported matrix. An explicit arm64 build prevents an accidental Intel support
claim. Ad-hoc local signing requires no Apple Developer Program membership and supplies code
integrity plus the entitlements needed by the local Apple-silicon application.

**Alternatives considered**:

- **Universal arm64/x86_64 output**: Conflicts with the clarified Apple-silicon-only scope and
  creates an Intel testing and maintenance obligation.
- **Script-only applet**: Apple notes that script-only apps may run under Rosetta as a precaution,
  and it does not eliminate reliance on scripting runtimes.
- **Hand-assembled Swift bundle**: Fewer project files but more custom signing, resource, and
  entitlement logic.

Sources: [Porting macOS apps to Apple silicon](https://developer.apple.com/documentation/apple-silicon/porting-your-macos-apps-to-apple-silicon)
and [Inside Code Signing Requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements/).

## Decision 6: Distribute Source and Build Locally With an Ad-Hoc Signature

**Decision**: Keep the stable bundle identifier `com.peterldowns.OpeniTerm` for migration
continuity. Enable Hardened Runtime and the Apple Events entitlement, but do not enable App Sandbox
or unrelated exceptions. Publish source and reproducible local-build instructions only. The build
uses Team None and an ad-hoc identity; no Developer ID identity, notarization, stapling, official
application download, or Apple credentials are required.

**Rationale**: This matches the personal-use scope and the user's existing unidentified-developer
expectation without creating a paid-program dependency. An ad-hoc signature does not authenticate
a publisher and may cause privacy authorization to be requested again after a rebuild. Supported
installation therefore begins from a local source build. If macOS rejects a copied or downloaded
build, documentation directs the user to rebuild locally or use Apple's documented **Open Anyway**
flow after reviewing the trusted source. It never directs the user to disable Gatekeeper or remove
quarantine metadata.

**Alternatives considered**:

- **Developer ID and notarization**: Best suited to trusted public binary distribution, but it
  requires program membership and credentials that the clarified feature explicitly excludes.
- **Redistribute an ad-hoc-signed app**: Provides no stable publisher identity and is outside the
  supported source-build path.
- **Mac App Store**: Adds ownership, review, sandbox, and distribution scope not requested here.
- **Checked-in app bundle**: Blurs source and generated output and cannot carry reproducible
  maintainer-independent trust.

Sources: [Developer ID](https://developer.apple.com/support/developer-id/),
[Hardened Runtime](https://developer.apple.com/documentation/security/hardened-runtime), and
[Inside Code Signing Requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements/),
and [Open a Mac app from an unidentified developer](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unidentified-developer-mh40616/mac).

## Decision 7: Layer Automated Contracts and Manual Matrix Evidence

**Decision**: Unit-test target resolution, path handling, error mapping, and invocation state
transitions. Adapter tests use fakes for Finder and `NSWorkspace`. Build verification checks bundle
metadata, entitlements, ad-hoc signature, deployment target, and the arm64-only architecture.
Manual checks cover Finder toolbar/Services discovery, TCC prompts, iTerm2 lifecycle behavior,
installation, invalid Finder selections, and each available macOS/iTerm2 combination. Results
conform to
`contracts/compatibility-report.schema.json` and never record literal user paths. Artifact checks
require exactly one arm64 slice, a valid ad-hoc code signature, expected entitlements, and the
declared deployment target; Gatekeeper acceptance and notarization are not pass criteria.

**Rationale**: Pure logic can run quickly on every change, while system/UI behavior is recorded
where reliable headless automation is unavailable. Explicit `unverified` status prevents test gaps
from becoming compatibility claims.

**Alternatives considered**:

- **Manual-only validation**: Too easy to regress quoting, input resolution, or metadata.
- **UI automation for every Finder flow**: Brittle, permission-heavy, and unsuitable as the only
  evidence.
- **Claim support from successful compilation**: Does not establish Finder, iTerm2, or TCC behavior.

## Decision 8: Remove Legacy Artifacts Only After Parity

**Decision**: Build and validate the native application before deleting `application/`, `service/`,
`Open iTerm.app/`, `Open iTerm.workflow/`, `build.py`, and `detect_version.applescript`. The first
modern source version documents removal of the old workflow, local building and installation of
the new app, toolbar reattachment, Services enablement, permissions, and rollback; its semantic
version is taken from project metadata rather than fixed by this plan.

**Rationale**: Keeping the old inputs until parity gives reviewers a behavior reference; removing
them afterward prevents two conflicting build and distribution paths.

**Alternatives considered**:

- **Maintain both implementations indefinitely**: Doubles testing and preserves the obsolete
  architecture.
- **Delete legacy artifacts before parity**: Removes the most direct comparison point.
