import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            AccountSettingsSection()
            LaunchSettingsSection()
        }
        .formStyle(.grouped)
        .frame(maxWidth: 480, minHeight: 240)
    }
}
