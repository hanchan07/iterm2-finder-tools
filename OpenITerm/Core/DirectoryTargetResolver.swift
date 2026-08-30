import Foundation

enum FileSystemItemKind {
    case directory
    case alias
    case regularFile
    case other
}

protocol FileSystemInspecting {
    func itemKind(at url: URL) throws -> FileSystemItemKind
    func resolvingAlias(at url: URL) throws -> URL
}

struct LocalFileSystem: FileSystemInspecting {
    func itemKind(at url: URL) throws -> FileSystemItemKind {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isAliasFileKey, .isRegularFileKey])
        if values.isAliasFile == true { return .alias }
        if values.isDirectory == true { return .directory }
        if values.isRegularFile == true { return .regularFile }
        return .other
    }

    func resolvingAlias(at url: URL) throws -> URL {
        try URL(resolvingAliasFileAt: url, options: [.withoutUI])
    }
}

public protocol DirectoryTargetResolving {
    func resolve(_ urls: [URL]) -> Result<DirectoryTarget, LaunchFailure>
}

public struct DirectoryTargetResolver: DirectoryTargetResolving {
    private let fileSystem: any FileSystemInspecting

    public init() {
        self.fileSystem = LocalFileSystem()
    }

    init(fileSystem: any FileSystemInspecting) {
        self.fileSystem = fileSystem
    }

    public func resolve(_ urls: [URL]) -> Result<DirectoryTarget, LaunchFailure> {
        guard urls.count == 1 else {
            return .failure(urls.isEmpty ? .emptySelection : .multipleSelection)
        }

        return resolveOne(urls[0], visitedAliases: [])
    }

    private func resolveOne(
        _ url: URL,
        visitedAliases: Set<URL>
    ) -> Result<DirectoryTarget, LaunchFailure> {
        guard url.isFileURL else {
            return .failure(.invalidTarget)
        }

        do {
            switch try fileSystem.itemKind(at: url) {
            case .alias:
                guard !visitedAliases.contains(url) else {
                    return .failure(.invalidAlias)
                }
                do {
                    let resolvedURL = try fileSystem.resolvingAlias(at: url)
                    return resolveOne(resolvedURL, visitedAliases: visitedAliases.union([url]))
                } catch {
                    return .failure(.invalidAlias)
                }
            case .directory:
                guard let target = DirectoryTarget(url: url) else {
                    return .failure(.invalidTarget)
                }
                return .success(target)
            case .regularFile:
                return .failure(.regularFile)
            case .other:
                return .failure(.invalidTarget)
            }
        } catch {
            return .failure(.targetUnavailable)
        }
    }
}
