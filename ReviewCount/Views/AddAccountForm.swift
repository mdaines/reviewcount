import SwiftUI

struct AddAccountForm: View {
    @EnvironmentObject private var model: ReviewCountModel

    let setUserInfo: (UserInfo) -> Void

    @State private var apiToken = ""

    @State private var error: Error?

    @Environment(\.dismiss) private var dismiss

    private var isAddAccountDisabled: Bool {
        apiToken.isEmpty
    }

    var body: some View {
        Form {
            Section("Add your WaniKani account") {
                SecureField("API Token", text: $apiToken, prompt: Text("WaniKani API Token"))

                if let error {
                    Group {
                        if let waniKaniError = error as? WaniKaniError, case .unauthorizedError = waniKaniError {
                            Text("Unauthorized API token.")
                        } else {
                            Text("Couldn't validate the API token.")
                        }
                    }
                    .foregroundStyle(.red)
                }

                HStack {
                    Button("Create a Token on WaniKani") {
                        NSWorkspace.shared.open(URL(string: "https://www.wanikani.com/settings/personal_access_tokens")!)
                    }

                    Spacer()

                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Add Account", action: addAccount)
                        .keyboardShortcut(.defaultAction)
                        .disabled(isAddAccountDisabled)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func addAccount() {
        Task {
            do {
                let userInfo = try await model.addAccount(apiToken: apiToken)

                setUserInfo(userInfo)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}
