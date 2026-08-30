# Tasks: Modernize macOS Support

**Input**: Design documents from `specs/001-modernize-macos-support/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, and
`quickstart.md`

**Verification**: Automated contract and path tests plus recorded manual Finder, iTerm2,
permission, installation, and compatibility checks are required by the specification and
constitution.

**Organization**: Tasks are grouped by user story so each increment can be implemented and
validated with explicit evidence.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: May run in parallel after its stated prerequisites because it changes different files.
- **[Story]**: Maps a task to User Story 1, 2, or 3 from `spec.md`.
- Every task names the exact repository path it creates, updates, validates, or removes.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the verified legacy baseline, reproducible arm64 Swift/AppKit project,
local-build tooling, compatibility-report contract, and required iTerm2 installations.

- [X] T001 Accept the installed Xcode license, capture `xcodebuild -version`, `swift --version`, `sw_vers`, `uname -m`, and installed iTerm2 versions, and record the verified baseline and any unavailable macOS 27 environment in `docs/compatibility/toolchain-baseline.md`
- [X] T002 Capture the legacy application's current behavior on Apple silicon in `docs/compatibility/legacy-baseline.md`, including macOS version, hardware and binary architectures, installation and Finder invocation results, observed failures, permission prompts, and reproducible steps; keep the replacement architecture provisional until this evidence is recorded
- [X] T003 Create the `OpenITerm` macOS app and test targets with Swift 6, macOS 26.0 deployment, `ARCHS=arm64`, Team None, Sign to Run Locally, Hardened Runtime, no Finder bridging-header setting yet, and no third-party runtime dependencies in `OpenITerm.xcodeproj/project.pbxproj`
- [X] T004 [P] Ignore `build/`, Derived Data, generated app bundles, archives, and local compatibility scratch data while preserving versioned reports in `.gitignore`
- [X] T005 [P] Define `com.peterldowns.OpeniTerm`, `LSUIElement`, Finder-only `NSServices` metadata with `NSSendFileTypes = public.item`, and the Finder Apple Events usage description in `OpenITerm/Resources/Info.plist`
- [X] T006 [P] Add only `com.apple.security.automation.apple-events = true` and exclude network, Accessibility, broad-file, JIT, DYLD, debugger, and disabled-library-validation exceptions in `OpenITerm/Resources/OpenITerm.entitlements`
- [X] T007 [P] Create the asset catalog and migrate the existing toolbar icon source from `Open iTerm.app/Contents/Resources/iTerm.icns` into `OpenITerm/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- [X] T008 [P] Create a deterministic Release build command using Team None, `ARCHS=arm64`, and the ad-hoc identity in `scripts/build.sh`
- [X] T009 [P] Create initial bundle, deployment-target, architecture, signature, and entitlement assertions for `build/Open iTerm.app` in `scripts/verify-artifact.sh`
- [X] T010 [P] Create a schema-conforming source-local-build report template covering runtime cases, Service selections, environment checks, arm64, ad-hoc signing, and unverified configurations in `docs/compatibility/report-template.json`
- [X] T011 Add `scripts/validate-compatibility-reports.sh` using pinned `ajv-cli@5.0.0` and `ajv-formats@2.1.1` with Draft 2020-12 validation, validate `docs/compatibility/report-template.json` against `specs/001-modernize-macos-support/contracts/compatibility-report.schema.json`, and record the command and result in `docs/compatibility/report-template.validation.md`
- [X] T012 Record the exact installed iTerm2 3.6.11 and any available iTerm2 3.7 prerelease versions and application paths in `docs/compatibility/toolchain-baseline.md`; record an unavailable prerelease as unverified without blocking the iTerm2 3.6.11 implementation gate

**Checkpoint**: The legacy failure is recorded, the project and test target can be opened and
built locally without Developer ID credentials or notarization, the evidence template validates,
and the installed iTerm2 3.6.11 gate environment is recorded; unavailable future matrix versions
are explicitly unverified.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Prove the launch mechanism first, then establish shared transient models and adapters.

**⚠️ CRITICAL**: T014 is a hard gate. If any required lifecycle state fails, stop implementation
and amend `research.md` and `plan.md`; do not add AppleScript, Python, or shell fallbacks.

- [X] T013 Build the minimal `NSWorkspace` directory-URL spike harness before production implementation in `OpenITermTests/ITermLaunchContractTests.swift`
- [X] T014 Run the T013 spike against installed iTerm2 3.6.11 for stopped, usable-window, and no-usable-window states, verify launch, reuse, the resulting working directory, timeouts, and errors, and record pass/fail evidence plus the stop decision in `docs/compatibility/nsworkspace-spike.md`; record unavailable iTerm2 3.7 validation as unverified
- [X] T015 Implement `Invocation`, `LaunchRequest`, source enumeration, transient timing, and no-persistence rules in `OpenITerm/Core/Invocation.swift`
- [X] T016 [P] Implement the absolute file-URL `DirectoryTarget` and `finderWindow`, `selectedDirectory`, and `resolvedAlias` origins in `OpenITerm/Core/DirectoryTarget.swift`
- [X] T017 [P] Implement `LaunchOutcome`, required error categories, duration, and path-free developer/user diagnostics in `OpenITerm/Core/LaunchOutcome.swift`
- [X] T018 Create the injectable file-system and alias-resolution boundary plus the resolver interface in `OpenITerm/Core/DirectoryTargetResolver.swift`
- [X] T019 Implement bundle-identifier discovery for `com.googlecode.iterm2` without assuming `/Applications` in `OpenITerm/Integrations/ITermApplicationLocator.swift`
- [X] T020 Implement the production asynchronous `NSWorkspace` URL-opening adapter using the T014-validated behavior in `OpenITerm/Integrations/ITermLauncher.swift`

**Checkpoint**: The launch mechanism is proven on installed iTerm2 3.6.11, and shared types are
ready for either Finder entry point. Future matrix versions remain unverified until tested.

---

## Phase 3: User Story 1 - Open the Finder Directory on Apple Silicon (Priority: P1) 🎯 MVP

**Goal**: Both the Finder toolbar app and contextual Service open exactly one Finder folder in
iTerm2 with the required stopped/windowed/no-window behavior on arm64.

**Independent Test**: On each available declared configuration, invoke both entry points from a
known folder for every iTerm2 lifecycle state and confirm 20/20 exact-directory results without
Rosetta, with at least 19/20 sessions ready within five seconds.

### Tests for User Story 1

> Write these tests first and confirm they fail before implementing the corresponding production
> behavior.

- [ ] T021 [P] [US1] Add failing toolbar and Service contract tests for front-window lookup, one-folder input, lifecycle requests, missing Finder window, denied Automation, and missing iTerm2 in `OpenITermTests/FinderEntryPointContractTests.swift`
- [ ] T022 [P] [US1] Add failing basic resolver tests for one selected folder, empty input, regular files, multiple items, and folder aliases in `OpenITermTests/DirectoryTargetResolverTests.swift`
- [X] T023 [P] [US1] Generate and check in only the Finder scripting declarations needed to read the front window target in `OpenITerm/Integrations/FinderScriptingBridge.h`
- [X] T024 [US1] Configure `SWIFT_OBJC_BRIDGING_HEADER` for the application target in `OpenITerm.xcodeproj/project.pbxproj` after T023 creates `OpenITerm/Integrations/FinderScriptingBridge.h`

### Implementation for User Story 1

- [X] T025 [US1] Implement front Finder window directory lookup and map missing-window and Automation-denied failures in `OpenITerm/Integrations/FinderLocationProvider.swift`
- [X] T026 [US1] Implement exact-one-existing-folder resolution with regular-file, empty, multiple, missing, and invalid-alias rejection in `OpenITerm/Core/DirectoryTargetResolver.swift`
- [X] T027 [US1] Implement the Finder Service pasteboard handler, `public.item` URL extraction, exact-one-folder enforcement, and localized Service errors in `OpenITerm/Integrations/ServiceProvider.swift`
- [X] T028 [US1] Wire toolbar launch, Service registration, dependency composition, actionable alerts, activation, and termination after success or failure in `OpenITerm/AppDelegate.swift`
- [ ] T029 [US1] Run the US1 automated contracts and record command output, source revision, toolchain, and any failures without literal user paths in `docs/compatibility/us1-automated.md`
- [ ] T030 [US1] Execute 20 consecutive toolbar and Service trials for all three iTerm2 lifecycle states on macOS 26 with iTerm2 3.6.11, record durations and exact-directory outcomes, mark unavailable configurations unverified in `docs/compatibility/macos-26-iterm-3.6.11.json`, and validate the report with `scripts/validate-compatibility-reports.sh`

**Checkpoint**: User Story 1 is a complete MVP: both Finder entry points open the intended folder
in iTerm2 on Apple silicon with recorded lifecycle evidence.

---

## Phase 4: User Story 2 - Handle Real macOS Paths Safely (Priority: P2)

**Goal**: Every valid Finder directory remains literal URL data, while invalid or unavailable
targets fail without shell interpretation, fallback directories, leaked paths, or unrelated file
reads.

**Independent Test**: Run the fixed path and selection corpus through the resolver contract
harness and both Finder entry points; verify exact directories, zero unintended commands, and
actionable failures for every invalid case.

### Tests for User Story 2

> Write these tests first and confirm they fail before extending production behavior.

- [ ] T031 [P] [US2] Add failing resolver tests for aliases to folders/files, unresolved aliases, disappeared targets, non-file URLs, symlinks, and no-fallback behavior in `OpenITermTests/DirectoryTargetResolverTests.swift`
- [ ] T032 [P] [US2] Add the literal path corpus for spaces, quotes, semicolons, dollar signs, backticks, newlines, leading hyphens, Unicode, emoji, removable/non-startup volumes, and simulated network, read-only, protected, and disconnected targets in `OpenITermTests/PathCorpusTests.swift`
- [ ] T033 [P] [US2] Add adapter tests proving exact URL preservation, target revalidation, no `cd`/shell construction, no alternate-terminal fallback, and path-free errors in `OpenITermTests/ITermLaunchContractTests.swift`

### Implementation for User Story 2

- [ ] T034 [US2] Complete safe alias resolution, file metadata checks without reading contents, URL-scheme validation, disappeared-target handling, and literal URL preservation in `OpenITerm/Core/DirectoryTargetResolver.swift`
- [ ] T035 [US2] Harden Service URL decoding and rejection paths so regular files, mixed selections, and malformed pasteboards never launch iTerm2 in `OpenITerm/Integrations/ServiceProvider.swift`
- [ ] T036 [US2] Revalidate the directory immediately before handoff and preserve the typed URL without shell or text conversion in `OpenITerm/Integrations/ITermLauncher.swift`
- [ ] T037 [US2] Add localized, actionable, literal-path-free descriptions for every resolver, Finder, permission, iTerm2, and unexpected failure category in `OpenITerm/Core/LaunchOutcome.swift`
- [ ] T038 [US2] Present US2 failures without home-directory fallback, persistent logging, telemetry, or retained target paths in `OpenITerm/AppDelegate.swift`
- [ ] T039 [US2] Run the US2 automated resolver, launch-contract, and path-corpus suites and record sanitized results in `docs/compatibility/us2-automated.md`
- [ ] T040 [US2] Exercise both Finder entry points against the complete valid/invalid corpus, network-mounted, read-only, protected, removable, disconnected-volume, and repeated-launch edge cases, add the sanitized evidence to `docs/compatibility/macos-26-iterm-3.6.11.json`, and validate the updated report with `scripts/validate-compatibility-reports.sh`

**Checkpoint**: User Story 2 independently proves literal path preservation and safe rejection
through automated adapters; its end-to-end evidence extends the US1 Finder entry points.

---

## Phase 5: User Story 3 - Install and Maintain Compatibility (Priority: P3)

**Goal**: A user can build, install, authorize, use, troubleshoot, and remove the personal arm64
app from source, while a future maintainer can repeat and record compatibility checks.

**Independent Test**: From a clean supported account and source checkout, follow only repository
documentation to build, install, authorize, use, and remove both entry points, then complete the
future-version checklist and compatibility record within 30 minutes excluding OS installation.

### Tests and Evidence Contracts for User Story 3

- [ ] T041 [P] [US3] Write prerequisites, Xcode license setup, arm64 ad-hoc build commands, local installation, toolbar attachment, Service enablement, supported Open Anyway guidance, Automation permission, removal steps, and the development-only Node.js/`npx` evidence-validation prerequisite in `docs/build-and-install.md`
- [ ] T042 [P] [US3] Document replacement of the legacy Automator artifacts, intentional Intel removal, toolbar/Service reinstallation, rollback limits, and archived-version guidance in `docs/migration.md`
- [ ] T043 [P] [US3] Document missing iTerm2, missing Finder window, denied/repeated Automation prompts, missing Service registration, blocked personal builds, and unsupported copied binaries in `docs/troubleshooting.md`
- [ ] T044 [P] [US3] Create the macOS 27 and future-major-version checklist with the 30-day public-beta trigger, lifecycle/path/install/permission/artifact checks, evidence rules, and GA status update in `docs/compatibility/future-macos-checklist.md`

### Implementation for User Story 3

- [ ] T045 [US3] Replace legacy installation and build instructions with the source-only arm64 workflow and link all migration, troubleshooting, and compatibility documents in `README.md`
- [ ] T046 [US3] Finish clean-checkout Release builds with deterministic output under `build/`, explicit source/version metadata, Team None, and ad-hoc signing in `scripts/build.sh`
- [ ] T047 [US3] Enforce arm64-only architecture, macOS 26.0 minimum, bundle identity, `LSUIElement`, Hardened Runtime, ad-hoc integrity, exact entitlements, and absence of forbidden permissions in `scripts/verify-artifact.sh`
- [ ] T048 [US3] Build from a clean source checkout using only `docs/build-and-install.md`, run `scripts/verify-artifact.sh`, and record reproducibility, arm64, signing, entitlement, and source-revision evidence in `docs/compatibility/reproducible-build.md`
- [ ] T049 [US3] On a clean macOS 26 account, follow the documented install, toolbar, Service, Automation allow/deny, use, and removal flows, update the environment checks in `docs/compatibility/macos-26-iterm-3.6.11.json`, and validate the updated report with `scripts/validate-compatibility-reports.sh`
- [ ] T050 [US3] Verify the documented trusted-source Open Anyway path when applicable and whether an ad-hoc rebuild repeats Automation permission, record the observed trust behavior without weakening Gatekeeper in `docs/compatibility/macos-26-iterm-3.6.11.json`, and validate the updated report with `scripts/validate-compatibility-reports.sh`
- [ ] T051 [US3] Execute the full macOS 27 and recorded iTerm2 3.7 prerelease matrix when available, or record every unavailable case explicitly as unverified without a support claim in `docs/compatibility/macos-27-iterm-3.7.json`, then validate the report with `scripts/validate-compatibility-reports.sh`
- [ ] T052 [US3] Have a maintainer unfamiliar with the modernization execute and time the future-version checklist, then record completion, omissions, and any documentation fixes in `docs/compatibility/future-checklist-dry-run.md`

**Checkpoint**: User Story 3 provides a reproducible personal-use lifecycle and a repeatable,
honest compatibility-maintenance process without an official binary or Apple credentials.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Complete full-system evidence, security review, legacy removal, and clean-source
verification across all stories.

- [ ] T053 [P] Run the complete `xcodebuild test` suite and record the final command, toolchain, pass/fail totals, duration, and source revision in `docs/compatibility/final-automated.md`
- [ ] T054 [P] Review the final design for shell construction, literal-path persistence, telemetry, network access, broad file access, unnecessary entitlements, background persistence, and undocumented dependencies in `docs/compatibility/security-review.md`
- [ ] T055 Run every step in `specs/001-modernize-macos-support/quickstart.md` from a clean checkout and record deviations or documentation corrections in `docs/compatibility/quickstart-run.md`
- [ ] T056 Run `scripts/validate-compatibility-reports.sh` for every compatibility JSON report and confirm each declared configuration has pass, fail, or explicitly unverified runtime, selection, installation, permission, removal, and artifact evidence in `docs/compatibility/matrix-review.md`
- [ ] T057 After T055 and T056 prove native parity, remove `application/`, `service/`, `Open iTerm.app/`, `Open iTerm.workflow/`, `build.py`, and `detect_version.applescript`, and document the removed generated artifacts in `docs/migration.md`
- [ ] T058 Rebuild and rerun automated tests after legacy removal, verify no source or documentation references require the deleted build path, and record results in `docs/compatibility/post-removal-validation.md`
- [ ] T059 Perform the constitution and scope review for Finder-to-iTerm parity, arm64-only output, local signing, least privilege, evidence completeness, and absence of unrelated features in `docs/compatibility/final-review.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 starts immediately. T002 must complete before T003 makes the proposed
  replacement concrete. T004-T010 and T012 may be authored in parallel after their prerequisites
  exist; T011 depends on T010, and T012 depends on T001. Phase 2 can start once T012 records the
  installed iTerm2 3.6.11 environment; unavailable future versions are unverified.
- **Foundational (Phase 2)**: Depends on Phase 1. T013-T014 are the mandatory launch-adapter gate;
  T015-T020 MUST NOT begin until T014 passes. A T014 failure returns the feature to planning.
- **User Story 1 (Phase 3)**: Depends on the complete foundational phase and has no dependency on
  another user story.
- **User Story 2 (Phase 4)**: Automated resolver and adapter work depends only on the foundational
  phase; T040 depends on the US1 entry points from T025-T028 for end-to-end execution.
- **User Story 3 (Phase 5)**: Documentation work T041-T044 may begin after the foundation.
  Clean-account and matrix validation T048-T052 depend on the implemented US1 and US2 behavior.
- **Polish (Phase 6)**: Depends on all selected user stories. Legacy removal T057 is prohibited
  until T055-T056 pass, and T058-T059 depend on T057.

### User Story Dependencies

- **US1 (P1)**: Delivers the independently testable Finder-to-iTerm MVP after the foundational
  launch gate.
- **US2 (P2)**: Its pure resolver and adapter safety contracts are independently testable after
  foundation; its final manual evidence reuses US1 entry points.
- **US3 (P3)**: Its documentation artifacts can be developed independently, while clean-account
  validation consumes the completed US1/US2 application.

### Within Each User Story

- Write the listed tests before the corresponding implementation and confirm they initially fail.
- Complete models and pure resolution rules before integration adapters.
- Complete adapters before AppDelegate/Service orchestration.
- Do not parallelize manual Finder, iTerm2 lifecycle, Gatekeeper, or TCC checks that mutate the
  same application or privacy state.
- Record sanitized evidence before closing each story checkpoint.

### Parallel Opportunities

- Setup: T004-T010 and T012 can be split across project metadata, resources, scripts, evidence,
  and environment inspection after their stated prerequisites; T011 follows T010.
- Foundation: T016, T017, and later adapter files can be developed in parallel after T014 passes,
  subject to the explicit T015-T020 ordering above.
- US1: T021, T022, and T023 use different files and can run in parallel.
- US2: T031, T032, and T033 use different test files and can run in parallel.
- US3: T041-T044 create separate documentation files and can run in parallel.
- Polish: T053 and T054 can run in parallel before the sequential clean-checkout/removal gates.

---

## Parallel Example: User Story 1

```text
Task T021: Add Finder entry-point contract tests in OpenITermTests/FinderEntryPointContractTests.swift
Task T022: Add basic resolver tests in OpenITermTests/DirectoryTargetResolverTests.swift
Task T023: Generate the Finder interface in OpenITerm/Integrations/FinderScriptingBridge.h
```

## Parallel Example: User Story 2

```text
Task T031: Add alias and invalid-target tests in OpenITermTests/DirectoryTargetResolverTests.swift
Task T032: Add literal path fixtures in OpenITermTests/PathCorpusTests.swift
Task T033: Add URL-preservation tests in OpenITermTests/ITermLaunchContractTests.swift
```

## Parallel Example: User Story 3

```text
Task T010: Create docs/compatibility/report-template.json
Task T041: Create docs/build-and-install.md
Task T042: Create docs/migration.md
Task T043: Create docs/troubleshooting.md
Task T044: Create docs/compatibility/future-macos-checklist.md
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 setup.
2. Complete T013-T014 and stop immediately if the `NSWorkspace` lifecycle contract fails.
3. Complete the remaining foundational tasks T015-T020.
4. Complete User Story 1 tasks T021-T030.
5. Stop and validate the MVP using the US1 independent test and recorded evidence.

### Incremental Delivery

1. Setup + validated launch foundation establishes a safe implementation path.
2. US1 adds both Finder entry points and lifecycle parity.
3. US2 hardens literal path handling and invalid-input behavior.
4. US3 adds reproducible personal builds, documentation, and future-version evidence.
5. Polish validates the full system before removing legacy artifacts.

### Parallel Team Strategy

1. Complete setup and the T013-T014 launch gate serially.
2. After the gate, parallelize only the explicitly marked project, test, and documentation files.
3. Serialize Finder/iTerm2 lifecycle and privacy-state validation on each test account.
4. Merge story evidence before the final quickstart and legacy-removal gates.

---

## Notes

- `[P]` means the task changes a different file and has no dependency on another unfinished task
  in the same parallel batch.
- `[US1]`, `[US2]`, and `[US3]` provide direct traceability to `spec.md`.
- Generated app bundles remain under ignored `build/` and are never committed as official binaries.
- A missing macOS 27 environment is recorded as unverified, never silently treated as passing.
- Stop at any checkpoint when recorded evidence contradicts `plan.md` or a contract.
