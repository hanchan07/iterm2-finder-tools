public struct SingleInvocationCoordinator: Sendable {
    public enum State: Equatable, Sendable {
        case waiting
        case running
        case finished
    }

    public private(set) var state: State = .waiting

    public init() {}

    public mutating func begin() -> Bool {
        guard state == .waiting else { return false }
        state = .running
        return true
    }

    public mutating func finish() {
        guard state == .running else { return }
        state = .finished
    }
}
