import SwiftUI
import Sparkle

@main
struct ReviewCountApp: App {
    @StateObject private var reviewCountModel = ReviewCountModel()

    @StateObject private var updatesModel = UpdatesModel()

    var body: some Scene {
        MenuBarExtraScene()
            .environmentObject(reviewCountModel)
            .environmentObject(updatesModel)
    }
}
