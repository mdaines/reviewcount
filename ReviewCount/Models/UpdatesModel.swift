import SwiftUI
import Sparkle

class UpdatesModel: ObservableObject {
    @Published var canCheckForUpdates = false

    private let updaterController: SPUStandardUpdaterController

    init() {
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

        updaterController.updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }
}
