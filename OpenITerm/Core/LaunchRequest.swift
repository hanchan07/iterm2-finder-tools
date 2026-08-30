import Foundation

public struct LaunchRequest: Sendable {
    public let target: DirectoryTarget

    public init(target: DirectoryTarget) {
        self.target = target
    }
}
