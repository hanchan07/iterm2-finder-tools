import Foundation

public enum LaunchFailure: Error, Equatable, Sendable {
    case finderWindowUnavailable
    case automationDenied
    case emptySelection
    case multipleSelection
    case regularFile
    case invalidAlias
    case targetUnavailable
    case invalidTarget
    case iTermNotInstalled
    case iTermOpenFailed
    case unexpectedFailure

    public var userMessage: String {
        switch self {
        case .finderWindowUnavailable:
            "Open a Finder folder, then try again."
        case .automationDenied:
            "Allow Open iTerm to control Finder in System Settings, then try again."
        case .emptySelection:
            "Select one folder in Finder, then try again."
        case .multipleSelection:
            "Select only one folder in Finder, then try again."
        case .regularFile:
            "Select a folder rather than a file."
        case .invalidAlias:
            "The selected Finder alias does not resolve to an available folder."
        case .targetUnavailable:
            "That folder is no longer available."
        case .invalidTarget:
            "Finder did not provide a usable folder."
        case .iTermNotInstalled:
            "iTerm2 is not installed. Install iTerm2, then try again."
        case .iTermOpenFailed:
            "iTerm2 could not open the selected folder. Try again after opening iTerm2."
        case .unexpectedFailure:
            "Open iTerm could not complete the request. Please try again."
        }
    }
}

public typealias LaunchOutcome = Result<Void, LaunchFailure>
