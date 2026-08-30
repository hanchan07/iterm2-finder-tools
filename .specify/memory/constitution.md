<!--
Sync Impact Report
- Version change: unratified template -> 1.0.0
- Modified principles:
  - Template Principle 1 -> I. Preserve the Finder-to-iTerm Contract
  - Template Principle 2 -> II. Native macOS and Apple-Silicon Compatibility
  - Template Principle 3 -> III. Safe Path Handling and Least Privilege
  - Template Principle 4 -> IV. Compatibility Evidence Is Required
  - Template Principle 5 -> V. Minimal, Maintainable Modernization
- Added sections:
  - Platform and Product Constraints
  - Maintenance Workflow and Quality Gates
- Removed sections: None; template placeholders were resolved.
- Templates requiring updates:
  - ✅ updated: .specify/templates/plan-template.md
  - ✅ updated: .specify/templates/spec-template.md
  - ✅ updated: .specify/templates/tasks-template.md
  - ✅ reviewed, no files present: .specify/templates/commands/*.md
  - ✅ reviewed, no update required: README.md
- Follow-up TODOs: None.
-->
# iTerm2 Finder Tools Constitution

## Core Principles

### I. Preserve the Finder-to-iTerm Contract
Every supported entry point MUST open iTerm2 at the directory represented by the user's
current Finder context. The Finder toolbar application MUST use the front Finder window's
folder. The Finder service or its supported replacement MUST use the folder selected or
supplied by Finder. If iTerm2 is running, the tool MUST open a tab in an available window;
if no window exists, it MUST open a window; and if iTerm2 is not running, it MUST launch it.
Compatibility work MUST preserve these behaviors unless a specification explicitly documents
and justifies a user-visible migration. This contract is the entire product value and is
therefore the first acceptance gate for every change.

### II. Native macOS and Apple-Silicon Compatibility
Released artifacts MUST run on Apple-silicon Macs without Rosetta or another architecture
translation layer. Each feature specification MUST name its supported macOS and iTerm2
versions, and its plan MUST identify any architecture, signing, notarization, automation,
privacy, or Finder integration constraints. Obsolete platform APIs or generated artifacts
MUST be replaced when they prevent operation on the declared support matrix. Intel support
MUST NOT be removed accidentally; any deliberate support reduction requires an explicit
specification, migration note, and constitution-compliant review.

### III. Safe Path Handling and Least Privilege
Finder-provided paths MUST be treated as untrusted data and passed to iTerm2 without command
injection, truncation, or corruption. Spaces, quotes, shell metacharacters, Unicode, removable
volumes, and other valid macOS path forms MUST be covered by verification. The tool MUST NOT
read unrelated files, transmit data, require network access, or request permissions beyond
those necessary to obtain the Finder context and automate iTerm2. Any new entitlement,
permission prompt, external dependency, or shell execution path MUST be documented and
justified in the feature plan.

### IV. Compatibility Evidence Is Required
No platform-affecting change is complete until the primary Finder-to-iTerm journey is verified
against the support matrix declared by its specification. Verification MUST cover iTerm2
stopped, iTerm2 running with a window, and iTerm2 running without a usable window, wherever
those states are supported by the chosen implementation. Build and packaging checks MUST
confirm that produced artifacts target the intended architecture and macOS version. Automated
checks MUST be used where practical; manual checks are permitted for Finder, privacy, or UI
behavior that cannot be automated, but the exact steps and observed results MUST be recorded.

### V. Minimal, Maintainable Modernization
Changes MUST remain focused on opening iTerm2 at the Finder directory. A replacement
implementation MUST use supported macOS mechanisms and the smallest architecture that meets
the declared compatibility, security, and packaging requirements. New dependencies,
background processes, telemetry, settings, or unrelated features require explicit rationale
and measurable user value. Source inputs, build instructions, and generated release artifacts
MUST remain clearly separated and reproducible so a future maintainer can update the project
without relying on undocumented local state.

## Platform and Product Constraints

- The project is a local macOS Finder integration for iTerm2; it is not a general terminal
  launcher, file manager, or remote service.
- The supported macOS, CPU architecture, iTerm2, and distribution matrix MUST be stated in each
  compatibility feature's specification and reflected in user documentation before release.
- Release artifacts MUST be buildable from repository source with documented prerequisites and
  commands. Checked-in generated artifacts MUST identify their source inputs and version.
- User-facing installation, permission, signing, and troubleshooting instructions MUST match
  the shipped mechanism and current macOS terminology.
- The utility MUST remain local-only and MUST NOT collect analytics or user path data.

## Maintenance Workflow and Quality Gates

1. Establish and document the current failure on an affected supported configuration before
   selecting a replacement mechanism.
2. Define the support matrix, user journeys, migration boundaries, and measurable acceptance
   criteria in the feature specification.
3. Record platform research and architecture decisions in the implementation plan, including
   why the selected macOS integration remains supported.
4. Add verification tasks for path safety, lifecycle states, architecture, packaging,
   installation, and documentation before implementation tasks are considered complete.
5. Build from a clean checkout and record automated and manual validation evidence for every
   declared support configuration available to the maintainer.
6. Review the resulting diff for scope growth, unnecessary permissions, undocumented generated
   files, and any regression in the core Finder-to-iTerm contract.

## Governance

This constitution is the authoritative engineering policy for iTerm2 Finder Tools. Feature
specifications, plans, task lists, implementation changes, and release documentation MUST pass
its gates. A proposed exception MUST be documented in the plan's Complexity Tracking section
with the affected principle, concrete need, rejected simpler option, risk, and removal or
review condition.

Amendments require a written rationale, an impact review of dependent Spec Kit templates and
runtime documentation, and an update to the Sync Impact Report. Constitution versions follow
semantic versioning: MAJOR for incompatible principle or governance changes, MINOR for new or
materially expanded policy, and PATCH for non-semantic clarification. The amendment date MUST
change whenever the constitution content changes; the ratification date remains the original
adoption date.

Every implementation plan MUST perform the Constitution Check before research and again after
design. Every release review MUST confirm the declared support matrix, recorded verification
evidence, permission scope, reproducible build path, and documentation accuracy. Reviewers MUST
block changes with unexplained violations.

**Version**: 1.0.0 | **Ratified**: 2026-08-29 | **Last Amended**: 2026-08-29
