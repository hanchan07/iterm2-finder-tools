import AppKit
import OpenITermCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let automaticTerminationReason = "Open iTerm is completing a Finder handoff."
    private let serviceRequestGracePeriod = Duration.milliseconds(150)
    private let finderLocationProvider: any FinderLocationProviding = FinderLocationProvider()
    private let launcher: any ITermLaunching = ITermLauncher()
    private var serviceProvider: ServiceProvider?
    private var toolbarFallbackTask: Task<Void, Never>?
    private var invocationCoordinator = SingleInvocationCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination(automaticTerminationReason)
        NSApp.setActivationPolicy(.accessory)
        let provider = ServiceProvider(resolver: DirectoryTargetResolver()) { [weak self] result in
            self?.handleServiceRequest(result) ?? false
        }
        serviceProvider = provider
        NSApp.servicesProvider = provider

        // macOS can launch this app before delivering a Service request. Give that request a brief
        // opportunity to claim the single invocation before treating the launch as a toolbar click.
        let gracePeriod = serviceRequestGracePeriod
        toolbarFallbackTask = Task { @MainActor [weak self, gracePeriod] in
            try? await Task.sleep(for: gracePeriod)
            guard !Task.isCancelled else { return }
            self?.beginToolbarInvocation()
        }
    }

    private func handleServiceRequest(
        _ result: Result<DirectoryTarget, LaunchFailure>
    ) -> Bool {
        guard invocationCoordinator.begin() else { return false }
        toolbarFallbackTask?.cancel()
        toolbarFallbackTask = nil

        switch result {
        case .success(let target):
            launch(LaunchRequest(target: target))
        case .failure(let failure):
            // Let the Service method return its error string before terminating the provider app.
            DispatchQueue.main.async { [weak self] in
                self?.finish(with: .failure(failure), presentsFailureAlert: false)
            }
        }
        return true
    }

    private func beginToolbarInvocation() {
        guard invocationCoordinator.begin() else { return }

        // Bring an accessory application forward before macOS presents the Automation decision.
        NSApp.activate(ignoringOtherApps: true)
        switch finderLocationProvider.frontWindowDirectory() {
        case .success(let target):
            launch(LaunchRequest(target: target))
        case .failure(let failure):
            finish(with: .failure(failure))
        }
    }

    private func launch(_ request: LaunchRequest) {
        launcher.launch(request) { [weak self] outcome in
            Task { @MainActor [weak self] in
                self?.finish(with: outcome)
            }
        }
    }

    private func finish(
        with outcome: LaunchOutcome,
        presentsFailureAlert: Bool = true
    ) {
        invocationCoordinator.finish()
        if presentsFailureAlert, case .failure(let failure) = outcome {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Open iTerm"
            alert.informativeText = failure.userMessage
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        ProcessInfo.processInfo.enableAutomaticTermination(automaticTerminationReason)
        NSApp.terminate(nil)
    }
}
