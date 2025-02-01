import SwiftUI

struct UpdaterSettingsSection: View {
    @EnvironmentObject private var updaterModel: UpdaterModel

    var body: some View {
        Section("Software Update") {
            Button("Check for Updates…", action: updaterModel.checkForUpdates)
                .disabled(!updaterModel.canCheckForUpdates)

            Toggle("Automatically check for updates", isOn: $updaterModel.automaticallyChecksForUpdates)
        }
    }
}
