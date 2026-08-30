import AppKit
import OpenITermCore

protocol FinderLocationProviding {
    func frontWindowDirectory() -> Result<DirectoryTarget, LaunchFailure>
}

struct FinderLocationProvider: FinderLocationProviding {
    func frontWindowDirectory() -> Result<DirectoryTarget, LaunchFailure> {
        var finderError: NSError?
        guard let url = OpenITermCopyFrontFinderWindowURL(&finderError) else {
            return .failure(mapFinderError(finderError))
        }

        return DirectoryTargetResolver().resolve([url])
    }

    private func mapFinderError(_ error: Error?) -> LaunchFailure {
        guard let error else {
            return .finderWindowUnavailable
        }

        let nsError = error as NSError
        // Automation-denied errors are surfaced by Apple Event delivery. Do not retain their text:
        // it can contain user-specific application details.
        if nsError.domain == NSOSStatusErrorDomain, nsError.code == -1743 {
            return .automationDenied
        }
        return .unexpectedFailure
    }
}
