# Implementation Plan: Modernize macOS Support

**Branch**: `001-modernize-macos-support` | **Date**: 2026-08-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-modernize-macos-support/spec.md`

## Summary

Replace the legacy x86-only Automator application and separate workflow with one arm64
Swift/AppKit accessory application. The application remains draggable into the Finder toolbar and
also advertises an `NSServices` action that accepts exactly one Finder folder. Toolbar invocations
obtain the front Finder directory through a narrowly scoped Apple Event adapter; service
invocations receive a folder URL directly. Both paths resolve one directory URL and ask the
installed iTerm2 application to open that URL through `NSWorkspace`, avoiding shell-command
construction and iTerm2's deprecated AppleScript API. The supported distribution is repository
source plus reproducible personal-use build instructions. Local builds use Xcode's ad-hoc **Sign
to Run Locally** mode and require no Developer ID identity, notarization, or official binary.
The native replacement remains the proposed architecture until the legacy Apple-silicon baseline
records the current behavior and confirms the incompatibility that motivates replacement.

## Technical Context

**Language/Version**: Swift 6 language mode; Apple Swift 6.3.3 supplied by Xcode 26.6

**Primary Dependencies**: AppKit, Foundation, ScriptingBridge, UniformTypeIdentifiers; no
third-party runtime dependencies. Evidence validation uses pinned `ajv-cli@5.0.0` and
`ajv-formats@2.1.1` as development tooling, not as application dependencies.

**Storage**: No product storage; versioned compatibility reports are repository documentation

**Testing**: Swift Testing unit and adapter-contract tests; `xcodebuild` build and arm64 artifact
checks; manual Finder, iTerm2 lifecycle, privacy-permission, local-installation, and trust-status
validation

**Target Platform**: Native arm64 macOS accessory application; deployment target macOS 26.0, with
the declared validation matrix covering macOS 26 and macOS 27

**Compatibility Matrix**:

| macOS | CPU | iTerm2 | Validation requirement |
|-------|-----|--------|---------------------|
| macOS Tahoe 26.6 or later | Apple silicon M1 or later | Stable 3.6.11 or later | Required and release-blocking |
| macOS 27 public beta, then GA | Apple silicon M1 or later | Current 3.7 prerelease, then first compatible stable | Future validation; results remain unverified until that environment is available |

Distribution method: source checkout plus documented local build and installation. The target uses
`ARCHS=arm64`, Team None, Hardened Runtime, and an ad-hoc signature so it can carry the narrowly
scoped Apple Events entitlement on Apple silicon. No official prebuilt app, Developer ID identity,
notarization submission, stapling, or Gatekeeper-acceptance claim is required. A copied or
downloaded personal build is outside the supported distribution path. Documentation permits only
Apple's supported **Open Anyway** flow after source review or rebuilding locally when macOS rejects
a personal build.

**Project Type**: Small native macOS desktop accessory and Services provider

**Performance Goals**: A ready iTerm2 session at the exact directory within five seconds in at
least 95% of trials; no persistent background process after an invocation completes

**Constraints**: Local-only; arm64 only; no network entitlement, telemetry, path persistence,
shell command construction, Finder Sync misuse, Rosetta requirement, official binary publication,
or Apple Developer Program dependency. Finder Apple Events are the only cross-app permission
requested by the toolbar launcher. The current workstation has Xcode 26.6 installed, but its
license must be accepted before builds can run. Exact iTerm2 tab/window behavior from a directory
URL is a mandatory first production implementation gate; failure stops implementation and requires a plan
amendment before adopting the more complex iTerm2 Python API.
The gate uses installed iTerm2 3.6.11. iTerm2 3.7 and macOS 27 are future compatibility checks:
their absence is recorded as unverified and does not block implementation or a macOS 26 support
claim.

**Scale/Scope**: One app target, one test target, two Finder entry points, one resolved directory
per invocation, and 20 lifecycle trials per declared configuration

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

### Pre-Research Gate

| Gate | Status | Evidence |
|------|--------|----------|
| Core contract | PASS | Spec user story 1 preserves toolbar/service behavior and all iTerm2 lifecycle states. |
| Platform support | PASS | The matrix names macOS 26/27, arm64-only hardware, iTerm2 3.6/3.7, local ad-hoc signing, and source distribution; Intel removal is an explicit migration limitation. |
| Path safety and permissions | PASS | The design uses file URLs, forbids shell construction, and limits entitlements to Finder Apple Events. |
| Verification | PASS | Unit, contract, arm64 artifact, manual lifecycle, path-corpus, local-installation, and trust-status checks are required. |
| Maintainability | CONDITIONAL | The native design is provisional until the legacy Apple-silicon failure baseline is recorded before production implementation. |

### Post-Design Gate

| Gate | Status | Design evidence |
|------|--------|-----------------|
| Core contract | PASS | `contracts/finder-entrypoints.md` and `contracts/iterm-launch.md` define both entry points and outcomes. |
| Platform support | PASS | `contracts/release-artifact.md` fixes arm64 architecture, deployment, ad-hoc local signing, unsupported distribution boundaries, and permissions. |
| Path safety and permissions | PASS | `data-model.md` defines URL validation; contracts prohibit path-to-command conversion and path retention. |
| Verification | PASS | `quickstart.md` covers local builds, arm64 architecture, ad-hoc signatures, lifecycle states, paths, installation, and evidence records. |
| Maintainability | PASS | The project tree isolates pure resolution logic, system adapters, resources, tests, scripts, and generated output. |

No constitution exception is granted. Production implementation remains blocked until the legacy
baseline and mandatory iTerm2 lifecycle spike pass.

## Project Structure

### Documentation (this feature)

```text
specs/001-modernize-macos-support/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── compatibility-report.schema.json
│   ├── finder-entrypoints.md
│   ├── iterm-launch.md
│   └── release-artifact.md
├── checklists/
│   └── requirements.md
└── tasks.md                         # Created by /speckit-tasks, not this plan
```

### Source Code (repository root)

```text
OpenITerm.xcodeproj/
└── project.pbxproj

OpenITerm/
├── AppDelegate.swift
├── Core/
│   ├── DirectoryTarget.swift
│   ├── DirectoryTargetResolver.swift
│   ├── Invocation.swift
│   └── LaunchOutcome.swift
├── Integrations/
│   ├── FinderLocationProvider.swift
│   ├── FinderScriptingBridge.h
│   ├── ITermApplicationLocator.swift
│   ├── ITermLauncher.swift
│   └── ServiceProvider.swift
└── Resources/
    ├── Assets.xcassets/
    ├── Info.plist
    └── OpenITerm.entitlements

OpenITermTests/
├── DirectoryTargetResolverTests.swift
├── FinderEntryPointContractTests.swift
├── ITermLaunchContractTests.swift
└── PathCorpusTests.swift

scripts/
├── build.sh
├── validate-compatibility-reports.sh
└── verify-artifact.sh

docs/
├── build-and-install.md
├── migration.md
├── compatibility/
│   ├── legacy-baseline.md
│   ├── report-template.json
│   └── report-template.validation.md
└── troubleshooting.md

build/                                  # Generated and ignored

# Removed after native parity is verified
application/
service/
Open iTerm.app/
Open iTerm.workflow/
build.py
detect_version.applescript
```

**Structure Decision**: Use one Xcode macOS application target and one test target. Pure input and
path-resolution types live under `Core`; Apple platform and iTerm2 interactions live under
`Integrations` behind protocols so tests do not require Finder or iTerm2. Personal-use output is
built under ignored `build/`; distributable application bundles are not committed or published as
official releases. Legacy sources remain only until parity validation passes, then are removed
with their migration documented in the README and migration guide.

## Complexity Tracking

No constitution violations or justified complexity exceptions are present.

## Phase Outputs

- Phase 0 decisions and alternatives: [research.md](research.md)
- Phase 1 transient domain model and state transitions: [data-model.md](data-model.md)
- Finder, iTerm2, local-build, and evidence contracts: [contracts/](contracts/)
- Runnable end-to-end validation guide: [quickstart.md](quickstart.md)
- Agent context update: skipped because this repository does not contain
  `.specify/scripts/bash/update-agent-context.sh`; no agent configuration was synthesized.

The first production implementation task MUST run the iTerm2 launch-adapter spike defined in
`contracts/iterm-launch.md` against installed iTerm2 3.6.11. If any required lifecycle state fails,
implementation stops and this plan returns to research; no deprecated AppleScript fallback is
permitted without a documented constitution review. iTerm2 3.7 validation remains a future matrix
task and must be recorded as unverified until it can be performed.
