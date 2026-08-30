import AppKit

protocol ITermApplicationLocating {
    func locateITerm2() -> URL?
}

struct ITermApplicationLocator: ITermApplicationLocating {
    static let bundleIdentifier = "com.googlecode.iterm2"

    func locateITerm2() -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleIdentifier)
    }
}
