import Foundation
import XCTest
@testable import OpenITermCore

final class DirectoryTargetTests: XCTestCase {
    func testRejectsNonFileURL() {
        XCTAssertNil(DirectoryTarget(url: URL(string: "https://example.com")!))
    }

    func testRejectsRelativeFileURL() {
        XCTAssertNil(DirectoryTarget(url: URL(string: "file:relative")!))
    }

    func testPreservesLiteralAbsoluteFileURL() {
        let target = DirectoryTarget(url: URL(fileURLWithPath: "/private/tmp", isDirectory: true))
        XCTAssertEqual(target?.url.path, "/private/tmp")
    }
}

final class DirectoryTargetResolverTests: XCTestCase {
    private let directoryURL = URL(fileURLWithPath: "/private/tmp/open-iterm-directory", isDirectory: true)
    private let fileURL = URL(fileURLWithPath: "/private/tmp/open-iterm-file")
    private let aliasURL = URL(fileURLWithPath: "/private/tmp/open-iterm-alias")

    func testRequiresExactlyOneURL() {
        let resolver = DirectoryTargetResolver(fileSystem: StubFileSystem())

        XCTAssertEqual(resolver.resolve([]).failure, .emptySelection)
        XCTAssertEqual(resolver.resolve([directoryURL, fileURL]).failure, .multipleSelection)
    }

    func testResolvesDirectory() {
        let resolver = DirectoryTargetResolver(
            fileSystem: StubFileSystem(kinds: [directoryURL: .directory])
        )

        XCTAssertEqual(resolver.resolve([directoryURL]).success?.url, directoryURL)
    }

    func testRejectsRegularFile() {
        let resolver = DirectoryTargetResolver(
            fileSystem: StubFileSystem(kinds: [fileURL: .regularFile])
        )

        XCTAssertEqual(resolver.resolve([fileURL]).failure, .regularFile)
    }

    func testResolvesAliasToDirectory() {
        let resolver = DirectoryTargetResolver(
            fileSystem: StubFileSystem(
                kinds: [aliasURL: .alias, directoryURL: .directory],
                aliases: [aliasURL: directoryURL]
            )
        )

        XCTAssertEqual(resolver.resolve([aliasURL]).success?.url, directoryURL)
    }

    func testRejectsAliasCycle() {
        let secondAlias = URL(fileURLWithPath: "/private/tmp/open-iterm-second-alias")
        let resolver = DirectoryTargetResolver(
            fileSystem: StubFileSystem(
                kinds: [aliasURL: .alias, secondAlias: .alias],
                aliases: [aliasURL: secondAlias, secondAlias: aliasURL]
            )
        )

        XCTAssertEqual(resolver.resolve([aliasURL]).failure, .invalidAlias)
    }

    func testMapsInspectionErrorToUnavailable() {
        let resolver = DirectoryTargetResolver(
            fileSystem: StubFileSystem(failingURLs: [directoryURL])
        )

        XCTAssertEqual(resolver.resolve([directoryURL]).failure, .targetUnavailable)
    }
}

final class LaunchFailureTests: XCTestCase {
    func testUserMessagesNeverContainLiteralPaths() {
        for failure in LaunchFailure.allCasesForTesting {
            XCTAssertFalse(failure.userMessage.contains("/"), "Unexpected path-like message for \(failure)")
        }
    }
}

final class SingleInvocationCoordinatorTests: XCTestCase {
    func testOnlyFirstInvocationBegins() {
        var coordinator = SingleInvocationCoordinator()

        XCTAssertTrue(coordinator.begin())
        XCTAssertFalse(coordinator.begin())
        XCTAssertEqual(coordinator.state, .running)
    }

    func testFinishedInvocationCannotRestart() {
        var coordinator = SingleInvocationCoordinator()

        XCTAssertTrue(coordinator.begin())
        coordinator.finish()

        XCTAssertEqual(coordinator.state, .finished)
        XCTAssertFalse(coordinator.begin())
    }
}

private struct StubFileSystem: FileSystemInspecting {
    var kinds: [URL: FileSystemItemKind] = [:]
    var aliases: [URL: URL] = [:]
    var failingURLs: Set<URL> = []

    func itemKind(at url: URL) throws -> FileSystemItemKind {
        if failingURLs.contains(url) { throw StubError.unavailable }
        return kinds[url] ?? .other
    }

    func resolvingAlias(at url: URL) throws -> URL {
        guard let resolvedURL = aliases[url] else { throw StubError.unavailable }
        return resolvedURL
    }

    private enum StubError: Error {
        case unavailable
    }
}

private extension Result {
    var success: Success? {
        guard case .success(let value) = self else { return nil }
        return value
    }

    var failure: Failure? {
        guard case .failure(let error) = self else { return nil }
        return error
    }
}

private extension LaunchFailure {
    static let allCasesForTesting: [LaunchFailure] = [
        .finderWindowUnavailable,
        .automationDenied,
        .emptySelection,
        .multipleSelection,
        .regularFile,
        .invalidAlias,
        .targetUnavailable,
        .invalidTarget,
        .iTermNotInstalled,
        .iTermOpenFailed,
        .unexpectedFailure,
    ]
}
