# Contract: Local Personal Build Artifact

## Bundle Identity

| Property | Required value |
|----------|----------------|
| Product | `Open iTerm.app` |
| Executable | `Open iTerm` |
| Bundle identifier | `com.peterldowns.OpeniTerm` |
| Marketing version | Version-controlled project value |
| Minimum system version | `26.0` |
| Bundle package type | `APPL` |
| Agent application | `LSUIElement = true` |

The application advertises `NSServices` metadata for a Finder-only **Open iTerm** service with
`NSSendFileTypes = [public.item]`; runtime validation accepts exactly one folder. It includes an
accurate `NSAppleEventsUsageDescription` explaining that Finder access is used only to obtain the
front window's current folder for toolbar invocation.

## Architecture

- The executable MUST contain exactly one `arm64` slice and no `x86_64` slice.
- The build MUST set `ARCHS=arm64` explicitly rather than relying on Xcode's standard universal
  architecture set.
- `lipo -archs` and `file` results MUST be captured by compatibility verification.
- Runtime validation MUST confirm native execution rather than Rosetta translation.

## Entitlements and Runtime

- Hardened Runtime MUST be enabled.
- `com.apple.security.automation.apple-events = true` is the only resource-access entitlement.
- App Sandbox is not enabled for direct distribution.
- Network client/server, Accessibility, file-wide access, JIT, unsigned executable memory, DYLD,
  debugger, and disabled-library-validation entitlements MUST be absent.

## Local Signing and Trust Boundary

The supported build MUST:

1. Use Xcode's **Sign to Run Locally** mode with Team None and the ad-hoc identity.
2. Pass strict `codesign` integrity verification.
3. Preserve the expected Hardened Runtime and Apple Events entitlement.
4. Identify the source revision, Xcode version, build configuration, architecture, and local
   signing mode in its compatibility report.

Developer ID signing, secure timestamps, notarization, stapling, notary credentials, and
Gatekeeper acceptance are not completion gates. An ad-hoc signature establishes code integrity
but no trusted publisher identity. Documentation MUST support building from reviewed source and
MAY describe Apple's **Open Anyway** flow for a trusted personal build; it MUST NOT instruct users
to disable Gatekeeper or remove quarantine metadata. Rebuilding may cause macOS Automation
permission to be requested again because the ad-hoc code identity changes.

## Source and Generated Artifact Separation

- Xcode sources, project metadata, resources, tests, and build scripts are version controlled.
- `build/`, Derived Data, and generated app bundles are ignored.
- Generated application bundles MUST NOT be committed, published as official binaries, or treated
  as the supported distribution mechanism.
- Source-version notes identify the revision, app version/build number, required Xcode version,
  arm64-only scope, local ad-hoc signing status, Intel migration limitation, and matching
  compatibility report.
