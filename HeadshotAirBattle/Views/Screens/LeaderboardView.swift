import SwiftUI

struct LeaderboardView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                // Tab selector
                Picker("Leaderboard", selection: $viewModel.selectedTab) {
                    Text("Win Rate").tag("winRate")
                    Text("Wins").tag("wins")
                    Text("Games").tag("totalGames")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else if viewModel.entries.isEmpty {
                    Spacer()
                    Text("No data available")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(viewModel.entries.enumerated()), id: \.offset) { index, entry in
                                LeaderboardRow(rank: index + 1, entry: entry, tab: viewModel.selectedTab)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadLeaderboard()
        }
        .onChange(of: viewModel.selectedTab) { _ in
            Task { await viewModel.loadLeaderboard() }
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let tab: String

    var body: some View {
        HStack {
            Text("#\(rank)")
                .font(.headline)
                .foregroundColor(rankColor)
                .frame(width: 40)

            Text(entry.nickname)
                .foregroundColor(.white)

            Spacer()

            Text(valueText)
                .foregroundColor(.cyan)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white
        }
    }

    private var valueText: String {
        switch tab {
        case "winRate": return String(format: "%.1f%%", entry.winRate)
        case "wins": return "\(entry.wins)"
        default: return "\(entry.totalGames)"
        }
    }
}
