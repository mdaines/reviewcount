import SwiftUI

struct LaunchSettingsSection: View {
    @StateObject private var launchAtLogin = LaunchAtLogin()

    var body: some View {
        Section("Open at Login") {
            Toggle("Open ReviewCount at login", isOn: $launchAtLogin.isEnabled)
        }
    }
}
