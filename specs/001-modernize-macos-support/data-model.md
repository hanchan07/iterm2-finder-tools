# Data Model: Modernize macOS Support

The product has no persistent user data. These models are transient values used during one
invocation, plus a repository-stored compatibility record that contains no literal user paths.

## Invocation

Represents one request to open iTerm2 from Finder.

| Field | Type | Rules |
|-------|------|-------|
| `source` | `toolbar` or `service` | Required |
| `receivedAt` | monotonic timestamp | Used only for duration measurement; not persisted by the app |
| `inputURLs` | list of file URLs | Empty for toolbar; exactly one URL expected for service |

### State transitions

```text
received -> resolvingContext -> rejected
                            -> targetResolved -> locatingITerm -> iTermMissing
                                                              -> opening -> failed
                                                                         -> succeeded
```

The process exits after `rejected`, `iTermMissing`, `failed`, or `succeeded` is presented.

## DirectoryTarget

The validated directory iTerm2 must open.

| Field | Type | Rules |
|-------|------|-------|
| `url` | absolute file URL | Required; must exist and resolve to a directory at validation time |
| `origin` | `finderWindow`, `selectedDirectory`, or `resolvedAlias` | Required |
| `displayName` | string | Optional and used only for error/UI text |

### Validation rules

1. The URL scheme MUST be `file`.
2. A directory resolves to itself.
3. A regular file is invalid and MUST NOT resolve to its containing directory.
4. A Finder alias resolves before validation and is valid only when its target is one existing
   directory.
5. Empty, multiple, missing, or unsupported inputs fail rather than selecting a fallback directory.
6. The URL remains data; no model exposes a shell-command representation.

## LaunchRequest

Represents the handoff to iTerm2.

| Field | Type | Rules |
|-------|------|-------|
| `target` | `DirectoryTarget` | Required |
| `applicationBundleIdentifier` | string | Fixed to `com.googlecode.iterm2` |
| `activateApplication` | boolean | Always true for a user invocation |

## LaunchOutcome

The terminal state reported by the launch adapter.

| Field | Type | Rules |
|-------|------|-------|
| `status` | `succeeded` or `failed` | Required |
| `runningApplicationIdentifier` | string | Present on success; contains no path data |
| `errorCategory` | enum | Present on failure |
| `durationMilliseconds` | nonnegative integer | Transient metric |

`errorCategory` values are `finderUnavailable`, `noFinderWindow`, `invalidSelection`,
`targetUnavailable`, `permissionDenied`, `iTermNotInstalled`, `iTermOpenFailed`, and
`unexpectedFailure`.

Success from the adapter means macOS accepted the open request. End-to-end validation separately
confirms that the resulting iTerm2 session has the expected working directory.

## LocalBuildArtifact

Metadata required of the generated personal-use application. This model does not represent an
official downloadable binary.

| Field | Type | Rules |
|-------|------|-------|
| `productName` | string | `Open iTerm.app` |
| `bundleIdentifier` | string | `com.peterldowns.OpeniTerm` |
| `sourceRevision` | commit identifier | Required for reproducibility |
| `marketingVersion` | semantic version | Read from version-controlled project metadata |
| `buildNumber` | positive integer | Identifies the local build |
| `minimumSystemVersion` | version | `26.0` |
| `architectures` | set | MUST equal `{arm64}` |
| `buildConfiguration` | enum | `Release` for compatibility evidence |
| `xcodeVersion` | version string | Exact local toolchain used |
| `signingMode` | enum | MUST be `ad-hoc-local` (`Sign to Run Locally`, Team None) |

The generated app remains local and ignored by version control. Developer ID signing,
notarization, and publication as an official binary are outside this model.

## CompatibilityConfiguration

One declared environment in the support matrix.

| Field | Type | Rules |
|-------|------|-------|
| `macOSVersion` | version string | Exact tested build or version |
| `architecture` | `arm64` | Required |
| `iTermVersion` | version string | Exact tested version |
| `buildOrigin` | `source-local-build` | Required |
| `xcodeVersion` | version string | Required |
| `signingMode` | `ad-hoc-local` | Required |
| `supportStatus` | `supported`, `provisional`, or `unverified` | Required |

## RuntimeCompatibilityCase

Records one Finder-to-iTerm runtime outcome without storing the literal directory used.

| Field | Type | Rules |
|-------|------|-------|
| `entryPoint` | `toolbar` or `service` | Required |
| `iTermLifecycle` | `stopped`, `windowAvailable`, or `noUsableWindow` | Required |
| `pathCategory` | controlled string | Example: `spaces`, `quotes`, `unicode`, `removableVolume` |
| `result` | `pass`, `fail`, or `unverified` | Required |
| `durationMilliseconds` | nonnegative integer | Required for executed cases |
| `evidence` | repository-relative references | MUST NOT include a user path or secret |
| `notes` | string | Optional; MUST NOT include a literal tested path |

## ServiceSelectionCase

Records service input validation independently from iTerm2 lifecycle behavior.

| Field | Type | Rules |
|-------|------|-------|
| `selectionCategory` | enum | `oneFolder`, `regularFile`, `empty`, `multipleFolders`, `mixedSelection`, `aliasToFolder`, `aliasToFile`, `unresolvedAlias` |
| `result` | `pass`, `fail`, or `unverified` | Required |
| `evidence` | repository-relative references | MUST NOT include a user path or secret |
| `notes` | string | Optional; MUST NOT include a literal tested path |

## EnvironmentCheck

Records non-runtime evidence required for compatibility and installation claims.

| Field | Type | Rules |
|-------|------|-------|
| `category` | enum | `build`, `arm64Artifact`, `adHocSignature`, `install`, `toolbarRegistration`, `serviceRegistration`, `automationAllowed`, `automationDenied`, or `removal` |
| `result` | `pass`, `fail`, or `unverified` | Required |
| `evidence` | repository-relative references | MUST NOT include a user path or secret |
| `notes` | string | Optional; MUST NOT include a literal tested path |

## CompatibilityReport

A report relates one source version and revision to one or more `CompatibilityConfiguration`
values. Each configuration contains runtime cases, service-selection cases, and environment checks.
It validates against `contracts/compatibility-report.schema.json` before publication.
