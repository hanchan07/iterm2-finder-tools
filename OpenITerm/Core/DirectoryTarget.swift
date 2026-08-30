import Foundation

/// A validated, absolute directory URL. The URL remains URL data throughout the handoff.
public struct DirectoryTarget: Equatable, Sendable {
    public let url: URL

    public init?(url: URL) {
        guard url.isFileURL, url.path.hasPrefix("/") else {
            return nil
        }

        self.url = url
    }
}
