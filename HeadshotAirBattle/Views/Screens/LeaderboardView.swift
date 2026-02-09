import SwiftUI

struct LeaderboardView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var isAppeared = false

    var body: some View {
        SciFiBgView {
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
                        .tint(AppColors.accent)
                    Spacer()
                } else if viewModel.entries.isEmpty {
                    Spacer()
                    Text("No data available")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textMuted)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(viewModel.entries.enumerated()), id: \.offset) { index, entry in
                                LeaderboardRow(rank: index + 1, entry: entry, tab: viewModel.selectedTab)
                                    .opacity(isAppeared ? 1 : 0)
                                    .offset(x: isAppeared ? 0 : 30)
                                    .animation(
                                        .easeOut(duration: 0.25).delay(Double(index) * 0.06),
                                        value: isAppeared
                                    )
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isAppeared = true
            }
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
                .font(AppFonts.orbitron(14, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 40)

            Text(entry.nickname)
                .font(AppFonts.rajdhani(16, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Text(valueText)
                .font(AppFonts.medNumber)
                .foregroundColor(AppColors.accent)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0, green: 30/255, blue: 60/255).opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(rank <= 3 ? rankColor.opacity(0.3) : AppColors.borderLight, lineWidth: 1)
        )
    }

    private var rankColor: Color {
        switch rank {
        case 1: return AppColors.gold
        case 2: return Color.gray
        case 3: return AppColors.warning
        default: return AppColors.textSecondary
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
