import AppKit
import XCTest

final class ITermLaunchContractTests: XCTestCase {
    private let iTermBundleIdentifier = "com.googlecode.iterm2"
    private let spikeDirectoryEnvironmentKey = "OPEN_ITERM_SPIKE_DIRECTORY"

    func testSpikePreflightFindsInstalledITerm2() throws {
        XCTAssertNotNil(
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: iTermBundleIdentifier),
            "The lifecycle spike requires an installed iTerm2 bundle."
        )
    }

    /// Performs one observable macOS URL-open handoff only when an operator deliberately supplies
    /// a directory with `OPEN_ITERM_SPIKE_DIRECTORY`. Keeping this opt-in prevents a normal test
    /// run from launching or changing the user's iTerm2 state.
    func testDirectoryURLSpikeWhenExplicitlyEnabled() async throws {
        guard let rawDirectory = ProcessInfo.processInfo.environment[spikeDirectoryEnvironmentKey],
              !rawDirectory.isEmpty
        else {
            throw XCTSkip("Set \(spikeDirectoryEnvironmentKey) to run the interactive lifecycle spike.")
        }

        let directoryURL = URL(fileURLWithPath: rawDirectory, isDirectory: true)
        var isDirectory: ObjCBool = false
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory)
                && isDirectory.boolValue,
            "The supplied spike target must be an existing directory."
        )

        let launchError = await runDirectoryURLSpike(directoryURL: directoryURL)
        XCTAssertNil(launchError, "NSWorkspace reported an iTerm2 URL-open failure: \(String(describing: launchError))")
    }

    /// Manual harness for T014. It deliberately has no automatic invocation because the test
    /// matrix must control iTerm2's lifecycle state and inspect the resulting session directory.
    func runDirectoryURLSpike(
        directoryURL: URL
    ) async -> Error? {
        guard directoryURL.isFileURL else {
            return NSError(domain: "OpenITerm.Spike", code: 1)
        }

        guard let applicationURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: iTermBundleIdentifier
        ) else {
            return NSError(domain: "OpenITerm.Spike", code: 2)
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        return await withCheckedContinuation { continuation in
            NSWorkspace.shared.open(
                [directoryURL],
                withApplicationAt: applicationURL,
                configuration: configuration
            ) { _, error in
                continuation.resume(returning: error)
            }
        }
    }
}
