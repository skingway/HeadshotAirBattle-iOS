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
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.cyan)

                    // Nickname
                    VStack(spacing: 8) {
                        Text(appViewModel.nickname)
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Button("Edit Nickname") {
                            viewModel.newNickname = appViewModel.nickname  // 预填充当前昵称
                            viewModel.errorMessage = nil
                            viewModel.showEditNickname = true
                        }
                        .font(.caption)
                        .foregroundColor(.cyan)
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

                    // 成功消息
                    if let success = viewModel.successMessage {
                        Text(success)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // 错误消息（持久显示，不只在 alert 中）
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
