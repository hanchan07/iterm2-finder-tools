import AppKit
import OpenITermCore

protocol ITermLaunching {
    func launch(_ request: LaunchRequest, completion: @escaping @Sendable (LaunchOutcome) -> Void)
}

final class ITermLauncher: ITermLaunching {
    private let locator: ITermApplicationLocating
    private let resolver: any DirectoryTargetResolving

    init(locator: ITermApplicationLocating = ITermApplicationLocator(), resolver: any DirectoryTargetResolving = DirectoryTargetResolver()) {
        self.locator = locator
        self.resolver = resolver
    }

    func launch(_ request: LaunchRequest, completion: @escaping @Sendable (LaunchOutcome) -> Void) {
        switch resolver.resolve([request.target.url]) {
        case .failure(let failure):
            completion(.failure(failure))
        case .success(let validatedTarget):
            guard let applicationURL = locator.locateITerm2() else {
                completion(.failure(.iTermNotInstalled))
                return
            }

            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.open(
                [validatedTarget.url],
                withApplicationAt: applicationURL,
                configuration: configuration
            ) { _, error in
                completion(
                    error == nil
                        ? .success(())
                        : .failure(.iTermOpenFailed)
                )
            }
        }
    }
}
