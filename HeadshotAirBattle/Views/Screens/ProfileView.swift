import SwiftUI

struct ProfileView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isAppeared = false

    var body: some View {
        SciFiBgView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar
                    Circle()
                        .fill(AppColors.accentDim)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: appViewModel.isSignedInWithApple ? "apple.logo" : "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.accent)
                        )
                        .overlay(
                            Circle().stroke(AppColors.accentBorder.opacity(0.8), lineWidth: 2)
                        )
                        .shadow(color: AppColors.accentGlow.opacity(0.2), radius: 12)

                    // Nickname
                    VStack(spacing: 8) {
                        Text(appViewModel.nickname)
                            .font(AppFonts.orbitron(22, weight: .bold))
                            .foregroundColor(.white)

                        if appViewModel.isSignedInWithApple, let name = appViewModel.userProfile?.appleDisplayName {
                            Text(name)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Button("Edit Nickname") {
                            viewModel.newNickname = appViewModel.nickname
                            viewModel.errorMessage = nil
                            viewModel.showEditNickname = true
                        }
                        .font(AppFonts.rajdhani(14, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                    }

                    // Apple Sign-In prompt for anonymous users
                    if !appViewModel.isSignedInWithApple && !appViewModel.isOfflineMode {
                        Button(action: {
                            Task {
                                await appViewModel.signInWithApple()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "apple.logo")
                                    .font(.title3)
                                Text("Sign in with Apple")
                                    .font(AppFonts.buttonText)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)

                        Text("Sign in to save your progress across devices")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textMuted)
                    }

                    // Apple Sign-In feedback messages
                    if let success = appViewModel.successMessage {
                        Text(success)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.success)
                            .padding(8)
                            .background(AppColors.successDim)
                            .cornerRadius(8)
                    }
                    if let error = appViewModel.errorMessage {
                        Text(error)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.danger)
                            .padding(8)
                            .background(AppColors.dangerDim)
                            .cornerRadius(8)
                    }

                    // Stats
                    if let profile = appViewModel.userProfile {
                        SectionHeader(title: "Statistics")

                        CardView {
                            VStack(spacing: 0) {
                                StatRow(label: "Total Games", value: "\(profile.totalGames)")
                                DividerLine()
                                StatRow(label: "Wins", value: "\(profile.wins)")
                                DividerLine()
                                StatRow(label: "Losses", value: "\(profile.losses)")
                                DividerLine()
                                StatRow(label: "Win Rate", value: String(format: "%.1f%%", profile.winRate), highlight: true)
                                if let online = profile.onlineGames {
                                    DividerLine()
                                    StatRow(label: "Online Games", value: "\(online)", highlight: true)
                                }
                            }
                        }
                    }

                    // Success message
                    if let success = viewModel.successMessage {
                        Text(success)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.success)
                            .padding()
                            .background(AppColors.successDim)
                            .cornerRadius(8)
                    }

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.danger)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(AppColors.dangerDim)
                            .cornerRadius(8)
                    }

                    Spacer()
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

            // Banner ad at bottom
            VStack {
                Spacer()
                ConditionalBannerAd()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Edit Nickname", isPresented: $viewModel.showEditNickname) {
            TextField("New nickname", text: $viewModel.newNickname)
                .textInputAutocapitalization(.never)
            Button("Save") {
                Task {
                    await viewModel.updateNickname(appViewModel: appViewModel)
                }
            }
            .disabled(viewModel.isUpdating)
            Button("Cancel", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppFonts.medNumber)
                .foregroundColor(highlight ? AppColors.accent : .white)
        }
    }
}
