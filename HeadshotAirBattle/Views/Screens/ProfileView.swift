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

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Edit Nickname", isPresented: $viewModel.showEditNickname) {
            TextField("New nickname", text: $viewModel.newNickname)
            Button("Save") {
                Task {
                    try? await appViewModel.updateNickname(viewModel.newNickname)
                }
            }
            Button("Cancel", role: .cancel) {}
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
