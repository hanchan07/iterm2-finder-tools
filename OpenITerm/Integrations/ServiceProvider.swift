import AppKit
import OpenITermCore

@MainActor
final class ServiceProvider: NSObject {
    private let resolver: any DirectoryTargetResolving
    private let handleInvocation: (Result<DirectoryTarget, LaunchFailure>) -> Bool

    init(
        resolver: any DirectoryTargetResolving,
        handleInvocation: @escaping (Result<DirectoryTarget, LaunchFailure>) -> Bool
    ) {
        self.resolver = resolver
        self.handleInvocation = handleInvocation
    }

    @objc(openITermService:userData:error:)
    func openITermService(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] ?? []

        let result = resolver.resolve(urls)
        if case .failure(let failure) = result {
            error.pointee = failure.userMessage as NSString
        }

        if !handleInvocation(result), error.pointee == nil {
            error.pointee = "Open iTerm is already handling another request." as NSString
        }
    }
}
