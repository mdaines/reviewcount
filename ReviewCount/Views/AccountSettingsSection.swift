import SwiftUI
import os

enum UserInfoStatus {
    case none
    case error(Error)
    case some(UserInfo)
}

struct AccountSettingsSection: View {
    @EnvironmentObject private var model: ReviewCountModel
    
    @State private var userInfoStatus: UserInfoStatus = .none

    @State private var isShowingRemoveAccountConfirmation = false

    @State private var isShowingAddAccountSheet = false

    var body: some View {
        Section("WaniKani Account") {
            if Credentials.hasToken {
                HStack {
                    switch userInfoStatus {
                    case .none:
                        Group {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 24))

                            VStack(alignment: .leading) {
                                Text("username")
                                    .font(.headline)
                                Text("Level 1")
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .redacted(reason: .placeholder)

                    case .error:
                        Spacer()

                        Text("Couldn’t load account information.")
                            .foregroundStyle(.red)

                        Button("Try Again", action: loadUserInfo)

                        Spacer()

                    case .some(let userInfo):
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 24))

                        VStack(alignment: .leading) {
                            Text(verbatim: userInfo.username)
                                .font(.headline)
                            Text("Level \(userInfo.level, format: .number)")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
                .frame(minHeight: 36)

                Button("Remove Account…") {
                    self.isShowingRemoveAccountConfirmation = true
                }
            } else {
                Button("Add Account…") {
                    self.isShowingAddAccountSheet = true
                }
            }
        }
        .modifier(
            AddAccountSheetModifier(model: model, isPresented: $isShowingAddAccountSheet, action: addAccount)
        )
        .modifier(
            RemoveAccountConfirmationModifier(isPresented: $isShowingRemoveAccountConfirmation, action: removeAccount)
        )
        .onAppear {
            loadUserInfo()
        }
    }

    private func loadUserInfo() {
        guard let apiToken = Credentials.get() else { return }

        Task {
            do {
                self.userInfoStatus = .some(try await loadUser(apiToken: apiToken))
            } catch {
                self.userInfoStatus = .error(error)
            }
        }
    }

    private func addAccount(userInfo: UserInfo) {
        self.userInfoStatus = .some(userInfo)
    }

    private func removeAccount() {
        model.removeAccount()

        self.userInfoStatus = .none
    }
}

struct RemoveAccountConfirmationModifier: ViewModifier {
    let isPresented: Binding<Bool>
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                Text("Remove your WaniKani account from ReviewCount?"),
                isPresented: isPresented
            ) {
                Button("Remove Account", role: .destructive, action: action)
            }
    }
}

struct AddAccountSheetModifier: ViewModifier {
    @ObservedObject var model: ReviewCountModel
    let isPresented: Binding<Bool>
    let action: (UserInfo) -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: isPresented) {
                AddAccountForm(setUserInfo: action)
            }
    }
}
