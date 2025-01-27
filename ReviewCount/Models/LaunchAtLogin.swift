import ServiceManagement
import os

class LaunchAtLogin: ObservableObject {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "LaunchAtLogin")

    var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }

        set {
            objectWillChange.send()

            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                Self.logger.debug("Registration error: \(error.localizedDescription)")
            }
        }
    }
}
