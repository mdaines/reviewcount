import SwiftUI
import Sparkle

struct MenuBarExtraScene: Scene {
    @EnvironmentObject var model: ReviewCountModel

    @EnvironmentObject var updatesModel: UpdatesModel

    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra {
            ReviewCountStatusView(reviewCountInfo: model.reviewCountInfo)

            Button("Start Reviews", action: startReviews)

            Divider()

            Button("ReviewCount Settings…", action: openSettingsAndActivate)

            Button("Check for Updates…", action: updatesModel.checkForUpdates)
                .disabled(!updatesModel.canCheckForUpdates)

            Divider()

            Button("Quit ReviewCount") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            TurtleView(reviewCountInfo: model.reviewCountInfo)
                .onAppear {
                    if !Credentials.hasToken {
                        openSettingsAndActivate()
                    }
                }
        }

        Settings {
            SettingsView()
        }
    }

    private func startReviews() {
        model.openingStartReviews()
        NSWorkspace.shared.open(URL(string: "https://www.wanikani.com/subjects/review")!)
    }

    private func openSettingsAndActivate() {
        openSettings()
        NSApp.activate(ignoringOtherApps: true)
    }
}
