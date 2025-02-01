import SwiftUI
import Sparkle
import Combine

@MainActor
class UpdaterModel: ObservableObject {
    @Published private(set) var canCheckForUpdates = false

    @Published var automaticallyChecksForUpdates = false

    private var cancellables = [AnyCancellable]()

    private let updaterController: SPUStandardUpdaterController

    private let updaterDelegate: UpdaterDelegate

    init() {
        self.updaterDelegate = UpdaterDelegate()

        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: updaterDelegate)

        updaterController.updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheckForUpdates)

        updaterController.updater.publisher(for: \.automaticallyChecksForUpdates).assign(to: &$automaticallyChecksForUpdates)

        $automaticallyChecksForUpdates
            .dropFirst()
            .removeDuplicates()
            .assign(to: \.automaticallyChecksForUpdates, on: updaterController.updater)
            .store(in: &cancellables)
    }

    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }
}

fileprivate class UpdaterDelegate: NSObject, SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool {
        true
    }
}
