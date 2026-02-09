import SwiftUI

struct SettingsView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = SettingsViewModel()
    @State private var isAppeared = false

    var body: some View {
        SciFiBgView {
            ScrollView {
                VStack(spacing: 24) {
                    // Audio
                    CardView {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Audio")

                            Toggle("Sound Effects", isOn: $viewModel.audioEnabled)
                                .font(AppFonts.body)
                                .foregroundColor(.white)
                                .tint(AppColors.accent)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("BGM Volume: \(Int(viewModel.bgmVolume * 100))%")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Slider(value: $viewModel.bgmVolume, in: 0...1)
                                    .tint(AppColors.accent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("SFX Volume: \(Int(viewModel.sfxVolume * 100))%")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Slider(value: $viewModel.sfxVolume, in: 0...1)
                                    .tint(AppColors.accent)
                            }
                        }
                    }

                    // Account
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Account")

                            HStack {
                                Text("Status")
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.textSecondary)
                                Spacer()
                                Text(appViewModel.authProviderDisplayName)
                                    .font(AppFonts.medNumber)
                                    .foregroundColor(.white)
                            }

                            if appViewModel.isSignedInWithApple {
                                if let email = appViewModel.userProfile?.appleEmail {
                                    HStack {
                                        Text("Apple ID")
                                            .font(AppFonts.body)
                                            .foregroundColor(AppColors.textSecondary)
                                        Spacer()
                                        Text(email)
                                            .font(AppFonts.rajdhani(14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                    }
                                }

                                Button(action: {
                                    viewModel.showSignOutConfirm = true
                                }) {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("Sign Out")
                                            .font(AppFonts.buttonText)
                                    }
                                    .foregroundColor(AppColors.warning)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(AppColors.warning.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(AppColors.warning.opacity(0.3), lineWidth: 1)
                                    )
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
                                            .font(AppFonts.buttonText)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(AppColors.border, lineWidth: 1)
                                    )
                                }
                            }

                            // Sign-in feedback
                            if let success = appViewModel.successMessage {
                                Text(success)
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.success)
                            }
                            if let error = appViewModel.errorMessage {
                                Text(error)
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.danger)
                            }

                            DividerLine()

                            Button(action: {
                                viewModel.showDeleteConfirm = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Account")
                                        .font(AppFonts.buttonText)
                                }
                                .foregroundColor(AppColors.danger)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(AppColors.dangerDim)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppColors.dangerBorder, lineWidth: 1)
                                )
                            }
                        }
                    }

                    // Privacy & Legal
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Privacy & Legal")

                            Button(action: {
                                navigationPath.append(AppRoute.privacyPolicy)
                            }) {
                                HStack {
                                    Text("Privacy Policy")
                                        .font(AppFonts.body)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.textMuted)
                                }
                            }
                        }
                    }

                    // About
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "About")

                            StatRow(label: "Version", value: "1.0.0")
                            DividerLine()
                            StatRow(label: "Platform", value: "iOS")
                        }
                    }
                }
                .padding()
                .opacity(isAppeared ? 1 : 0)
                .offset(y: isAppeared ? 0 : 20)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isAppeared = true
                    }
                }
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
