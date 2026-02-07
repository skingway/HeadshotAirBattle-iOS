import SwiftUI

struct SettingsView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Audio
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Audio")
                            .font(.headline)
                            .foregroundColor(.cyan)

                        Toggle("Sound Effects", isOn: $viewModel.audioEnabled)
                            .foregroundColor(.white)
                            .tint(.cyan)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("BGM Volume: \(Int(viewModel.bgmVolume * 100))%")
                                .foregroundColor(.gray)
                            Slider(value: $viewModel.bgmVolume, in: 0...1)
                                .tint(.cyan)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("SFX Volume: \(Int(viewModel.sfxVolume * 100))%")
                                .foregroundColor(.gray)
                            Slider(value: $viewModel.sfxVolume, in: 0...1)
                                .tint(.cyan)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // Account
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account")
                            .font(.headline)
                            .foregroundColor(.cyan)

                        HStack {
                            Text("Status")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(appViewModel.authProviderDisplayName)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }

                        if appViewModel.isSignedInWithApple {
                            if let email = appViewModel.userProfile?.appleEmail {
                                HStack {
                                    Text("Apple ID")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(email)
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                }
                            }

                            Button(action: {
                                viewModel.showSignOutConfirm = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                            }
                        } else if !appViewModel.isOfflineMode {
                            Button(action: {
                                Task {
                                    await appViewModel.signInWithApple()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "apple.logo")
                                    Text("Sign in with Apple")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(8)
                            }
                        }

                        Divider().overlay(Color.gray.opacity(0.3))

                        Button(action: {
                            viewModel.showDeleteConfirm = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Account")
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // Privacy & Legal
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Privacy & Legal")
                            .font(.headline)
                            .foregroundColor(.cyan)

                        Button(action: {
                            navigationPath.append(AppRoute.privacyPolicy)
                        }) {
                            HStack {
                                Text("Privacy Policy")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // About
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(.cyan)

                        InfoRow(label: "Version", value: "1.0.0")
                        InfoRow(label: "Platform", value: "iOS")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Out", isPresented: $viewModel.showSignOutConfirm) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await appViewModel.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will be signed out of your Apple account. Your game data will be preserved locally.")
        }
        .alert("Delete Account", isPresented: $viewModel.showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    await appViewModel.deleteAccount()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
    }
}
