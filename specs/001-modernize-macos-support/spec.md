# Feature Specification: Modernize macOS Support

**Feature Branch**: No branch created (no `before_specify` hook configured)

**Created**: 2026-08-29

**Status**: Draft

**Input**: User description: "Update the code and application for Apple silicon and future macOS compatibility."

## Clarifications

### Session 2026-08-29

- Q: What release trust policy should the specification require? → A: Publish source and
  documented local-build instructions for personal use; an official Apple Developer certificate,
  notarization, and an official binary release are not required.
- Q: Should the modernization retain Intel support? → A: No. Support Apple silicon only and
  document removal of Intel support as a migration limitation.
- Q: Which contextual Finder selections should be accepted? → A: Preserve the legacy
  successful behavior: accept exactly one selected folder; reject regular files, empty input, and
  multiple selections with a clear failure.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open the Finder Directory on Apple Silicon (Priority: P1)

As an Apple-silicon Mac user, I can invoke an iTerm2 Finder entry point and receive an iTerm2
session whose working directory is the folder represented by my current Finder context.

**Why this priority**: Opening the correct Finder directory in iTerm2 is the product's core
purpose, and native Apple-silicon operation is the compatibility gap this feature must close.

**Independent Test**: On each supported Apple-silicon and macOS combination, invoke each shipped
Finder entry point from a known folder and confirm the resulting iTerm2 session reports that exact
folder as its working directory without architecture translation.

**Acceptance Scenarios**:

1. **Given** iTerm2 is not running and Finder is displaying a folder, **When** the user invokes the
   toolbar entry point, **Then** iTerm2 launches and opens a session in that folder.
2. **Given** iTerm2 has an available window and Finder is displaying a folder, **When** the user
   invokes the toolbar entry point, **Then** a new tab opens in an available window at that folder.
3. **Given** iTerm2 is running without a usable window, **When** the user invokes a Finder entry
   point for a folder, **Then** a new usable window opens with a session at that folder.
4. **Given** a folder is supplied through the Finder contextual entry point, **When** the user
   invokes the action, **Then** iTerm2 opens a session at the supplied folder.
5. **Given** the contextual entry point receives a regular file, no item, or multiple items,
   **When** the user invokes the action, **Then** it reports that exactly one folder is required and
   does not open an unrelated directory.

---

### User Story 2 - Handle Real macOS Paths Safely (Priority: P2)

As a user with folders whose names contain spaces, quotes, shell metacharacters, Unicode, or
volume-specific paths, I can open the folder in iTerm2 without path corruption or unintended
command execution.

**Why this priority**: A compatibility update is unsafe if a valid Finder path can select the
wrong directory or be interpreted as a command.

**Independent Test**: Invoke both Finder entry points for a fixed path corpus containing every
required path category and verify that each resulting session uses the exact intended directory
and produces no additional command or side effect.

**Acceptance Scenarios**:

1. **Given** a valid folder path contains spaces, quotes, shell metacharacters, or Unicode,
   **When** the user opens it through Finder, **Then** iTerm2 uses the complete literal path.
2. **Given** a valid folder is on a removable or non-startup volume, **When** the user opens it
   through Finder, **Then** iTerm2 uses the volume's exact mounted path.
3. **Given** Finder cannot provide a usable folder or the folder becomes unavailable, **When** the
   action runs, **Then** the user receives a clear failure and no unrelated directory is opened.

---

### User Story 3 - Install and Maintain Compatibility (Priority: P3)

As a user or maintainer, I can build and install the application for personal use through
documented macOS steps, understand its unsigned or locally signed trust status and any required
permissions, and repeat a defined compatibility check when Apple publishes a new major macOS
version.

**Why this priority**: A working source change has little value if users cannot install it or if
the next macOS change leaves maintainers without a repeatable validation path.

**Independent Test**: Starting from a clean supported Mac account and source checkout, follow only
the published build, installation, trust-confirmation, and permission instructions, complete the
primary journey, and then execute the published future-version compatibility checklist.

**Acceptance Scenarios**:

1. **Given** a clean supported Apple-silicon Mac account and source checkout, **When** the user
   follows the documented local-build and installation instructions, **Then** both shipped Finder
   entry points can be built, installed, and invoked without Rosetta or undocumented workarounds.
2. **Given** macOS requests permission for Finder or iTerm2 interaction, **When** the user follows
   the documentation, **Then** the purpose and minimum required permission are clear.
3. **Given** Apple publishes a public beta of a subsequent major macOS release, **When** a
   maintainer follows the compatibility checklist, **Then** the core journey, path safety,
   installation, permission, and lifecycle states can all be evaluated consistently.

### Edge Cases

- Finder has no open window when the toolbar entry point is invoked.
- The contextual entry point receives no directory, more than one item, a regular file, an alias
  that does not resolve to one folder, or a directory that disappears before iTerm2 opens it.
- iTerm2 is not installed, cannot launch, has no usable window, or rejects automation permission.
- A folder name contains spaces, single or double quotes, semicolons, dollar signs, backticks,
  newlines, leading hyphens, non-Latin characters, or emoji.
- A folder resides on a removable, network-mounted, read-only, protected, or disconnected volume.
- macOS blocks an artifact because required distribution trust or permission information is
  missing.
- Repeated invocations occur while iTerm2 is still launching.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The product MUST open iTerm2 at the directory represented by the invoking Finder
  context.
- **FR-002**: The toolbar entry point MUST use the front Finder window's displayed folder.
- **FR-003**: The contextual Finder entry point MUST accept exactly one selected folder and use
  that folder as its target. It MUST reject regular files, empty input, multiple selections, and
  aliases that do not resolve to exactly one usable folder with a clear, actionable failure.
- **FR-004**: The product MUST launch iTerm2 when it is stopped, open a new tab when a usable window
  exists, and open a new window when no usable window exists.
- **FR-005**: The product MUST preserve every supported path as literal data without truncation,
  substitution, or interpretation as an additional command.
- **FR-006**: The product MUST provide a clear, actionable failure when Finder cannot provide a
  usable directory, iTerm2 is unavailable, or required permission is denied.
- **FR-007**: Produced application builds MUST run natively on supported Apple-silicon Macs without
  Rosetta or another architecture translation layer.
- **FR-008**: Local build and installation MUST use documented macOS-supported user actions. The
  instructions MAY include macOS-supported confirmation for an unidentified developer or local
  signature, but MUST NOT depend on an undocumented security bypass.
- **FR-009**: The product MUST remain local-only, MUST NOT transmit or retain user paths, and MUST
  request only permissions necessary for Finder and iTerm2 interaction.
- **FR-010**: User documentation MUST describe source prerequisites, local build, installation,
  removal, unsigned or locally signed trust status, required permissions, supported versions,
  known limitations, and troubleshooting for blocked or denied actions.
- **FR-011**: The modernized application MUST support Apple-silicon Macs only. Documentation MUST
  identify removal of Intel support as an intentional migration limitation and direct Intel users
  to the archived legacy version without claiming compatibility with future macOS releases.
- **FR-012**: The release documentation MUST provide a repeatable checklist for evaluating each
  subsequent major macOS release before or at its general availability.
- **FR-013**: Completion MUST NOT require Apple Developer Program membership, Developer ID signing,
  notarization, or publication of an official binary; the supported distribution is source plus
  reproducible personal-use build instructions.

### Compatibility & Migration Requirements *(mandatory for platform-affecting work)*

- **CM-001**: The initial support matrix MUST include Apple-silicon Macs (M1 or later) running
  macOS Tahoe 26 and macOS 27, including the macOS 27 public beta while it remains prerelease.
- **CM-002**: The iTerm2 matrix MUST include the current stable release beginning with iTerm2
  3.6.11, plus the current iTerm2 3.7 prerelease while validating prerelease macOS 27.
- **CM-003**: Both the Finder toolbar entry point and the contextual Finder entry point, or a
  documented user-visible replacement for either, MUST preserve the Finder-to-iTerm directory
  contract.
- **CM-004**: Compatibility verification MUST cover iTerm2 stopped, running with a usable window,
  and running without a usable window on every declared configuration available for testing.
- **CM-005**: Compatibility verification MUST cover paths with spaces, quotes, shell
  metacharacters, Unicode, removable volumes, and unavailable-directory failures.
- **CM-006**: Compatibility validation MUST identify local build, installation, unsigned or locally
  signed distribution trust, Finder/iTerm2 automation, privacy permissions, and existing-user
  migration impacts.
- **CM-007**: Produced application builds and documentation MUST identify their supported macOS
  versions and arm64-only CPU architecture, and builds MUST not require Rosetta.
- **CM-008**: If a declared configuration cannot be tested, the release record MUST identify the
  missing evidence and MUST NOT claim that configuration as verified.
- **CM-009**: For each major macOS version after macOS 27, compatibility assessment MUST begin no
  later than 30 days after the first public beta and its support status MUST be documented by
  general availability.

### Scope Boundaries

**In scope**:

- Source, build, packaging, and documentation changes necessary to satisfy the Finder-to-iTerm
  contract on the declared Apple-silicon macOS and iTerm2 matrix.
- Installation, permission, migration, removal, and future-version compatibility guidance.
- Existing Finder toolbar and contextual entry points, including documented replacements when a
  current entry point is no longer supported by macOS.

**Out of scope**:

- Support for terminals other than iTerm2 or operating systems other than macOS.
- Intel-Mac builds, testing, and compatibility maintenance.
- New terminal-management features, settings synchronization, analytics, background services, or
  collection of user path data.
- Changes to iTerm2 itself or guarantees for unlisted prerelease combinations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The primary Finder-to-iTerm journey succeeds in 100% of 20 consecutive trials for
  every declared configuration tested, covering all three iTerm2 lifecycle states.
- **SC-002**: In at least 95% of trials, users receive a ready iTerm2 session at the exact Finder
  directory within five seconds of invoking the action, excluding iTerm2 installation time.
- **SC-003**: All cases in the required path corpus open the exact intended directory with zero
  unintended commands, substitutions, or fallback-directory successes.
- **SC-004**: A user starting with a clean supported Apple-silicon account and source checkout can
  build, install, authorize, use, and remove both Finder entry points by following the
  documentation with zero undocumented workarounds and without Rosetta.
- **SC-005**: Every declared configuration has a release record containing a pass, fail, or
  explicitly unverified result for the core journey, path corpus, lifecycle states, installation,
  permissions, and artifact compatibility.
- **SC-006**: A maintainer unfamiliar with the modernization can complete the future-major-version
  compatibility checklist and record all required results in 30 minutes or less, excluding
  operating-system installation time.

## Assumptions

- Users install iTerm2 separately; the compatibility baseline is iTerm2 3.6.11 or newer.
- macOS Tahoe 26 is the current generally available baseline, and macOS 27 is the next major
  release targeted during its public beta and at general availability.
- Apple-silicon support covers M1 and later Macs; older PowerPC hardware is outside scope.
- Intel compatibility is intentionally not retained; affected users may continue using the
  archived legacy version on its existing supported systems.
- Users may need to grant macOS permissions that are necessary for Finder and iTerm2 interaction;
  the product requests no broader access.
- The application is intended for personal use and is distributed as source with reproducible
  local-build instructions; Apple Developer Program credentials and an official binary release
  are not available or required.
- The utility operates entirely on the user's Mac and has no network, account, telemetry, or
  persistent user-data requirement.
- Apple and iTerm2 prerelease behavior may change; claims for prerelease configurations remain
  explicitly provisional until repeated against generally available releases.
