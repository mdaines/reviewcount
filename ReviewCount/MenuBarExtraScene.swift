import SwiftUI
import Sparkle

struct MenuBarExtraScene: Scene {
    @EnvironmentObject var model: ReviewCountModel

    @EnvironmentObject var updatesModel: UpdatesModel

    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra {
            reviewCountStatus()

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
            turtle()
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

    @ViewBuilder func turtle() -> some View {
        Image(systemName: "tortoise.fill")

        switch model.reviewCountInfo {
        case .none:
            EmptyView()
        case .error:
            Text("!")
        case .reviews(let availableSubjectIds, _):
            Text(availableSubjectIds.count, format: .number)
        }
    }

    @ViewBuilder
    private func reviewCountStatus() -> some View {
        switch model.reviewCountInfo {
        case .none:
            EmptyView()
        case .error(let error):
            Text("Error Checking Review Count")

            Text(verbatim: error.localizedDescription)
                .font(.caption)

            Button("Check Review Count") {
                model.reload()
            }

            Divider()
        case .reviews(let availableSubjectIds, let nextReviewsAt):
            if availableSubjectIds.count == 0 {
                if let nextReviewsAt {
                    Text("Next Reviews: \(nextReviewsAt, format: .dateTime)")
                } else {
                    Text("No Reviews Scheduled")
                }
            } else {
                Text("Reviews Available Now")
            }

            Button("Check Review Count") {
                model.reload()
            }

            Divider()
        }
    }
}
