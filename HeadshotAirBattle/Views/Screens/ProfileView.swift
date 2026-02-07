import SwiftUI

struct ProfileView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Avatar
                    Image(systemName: appViewModel.isSignedInWithApple ? "apple.logo" : "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.cyan)

                    // Nickname
                    VStack(spacing: 8) {
                        Text(appViewModel.nickname)
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        if appViewModel.isSignedInWithApple, let name = appViewModel.userProfile?.appleDisplayName {
                            Text(name)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Button("Edit Nickname") {
                            viewModel.newNickname = appViewModel.nickname
                            viewModel.errorMessage = nil
                            viewModel.showEditNickname = true
                        }
                        .font(.caption)
                        .foregroundColor(.cyan)
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
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)

                        Text("Sign in to save your progress across devices")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    // Stats
                    if let profile = appViewModel.userProfile {
                        VStack(spacing: 16) {
                            StatRow(label: "Total Games", value: "\(profile.totalGames)")
                            StatRow(label: "Wins", value: "\(profile.wins)")
                            StatRow(label: "Losses", value: "\(profile.losses)")
                            StatRow(label: "Win Rate", value: String(format: "%.1f%%", profile.winRate))
                            if let online = profile.onlineGames {
                                StatRow(label: "Online Games", value: "\(online)")
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Success message
                    if let success = viewModel.successMessage {
                        Text(success)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Spacer()
                }
                .padding()
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

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
    }
}
