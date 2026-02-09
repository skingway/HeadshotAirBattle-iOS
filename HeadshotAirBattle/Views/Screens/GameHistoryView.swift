import SwiftUI

struct GameHistoryView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = GameHistoryViewModel()
    @State private var filter: GameHistoryFilter = .all
    @State private var sortBy: GameHistorySort = .date
    @State private var isAppeared = false

    enum GameHistoryFilter: String, CaseIterable {
        case all = "All"
        case wins = "Wins"
        case losses = "Losses"
    }

    enum GameHistorySort: String, CaseIterable {
        case date = "Date"
        case result = "Result"
    }

    private var filteredGames: [GameHistoryEntry] {
        var result = viewModel.games
        switch filter {
        case .all: break
        case .wins: result = result.filter { $0.winner == appViewModel.userId }
        case .losses: result = result.filter { $0.winner != appViewModel.userId }
        }
        if sortBy == .result {
            result.sort { ($0.winner == appViewModel.userId ? 0 : 1) < ($1.winner == appViewModel.userId ? 0 : 1) }
        }
        return result
    }

    var body: some View {
        SciFiBgView {
            if viewModel.isLoading {
                ProgressView()
                    .tint(AppColors.accent)
            } else if viewModel.games.isEmpty {
                Text("No games played yet")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textMuted)
            } else {
                VStack(spacing: 0) {
                    // Filter and Sort controls
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            ForEach(GameHistoryFilter.allCases, id: \.self) { f in
                                Button(f.rawValue.uppercased()) {
                                    filter = f
                                }
                                .font(AppFonts.orbitron(10, weight: .bold))
                                .foregroundColor(filter == f ? .white : AppColors.textMuted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(filter == f ? AppColors.accent.opacity(0.3) : AppColors.accentSoft)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(filter == f ? AppColors.accentBorder : Color.clear, lineWidth: 1)
                                )
                            }
                            Spacer()
                            Menu {
                                ForEach(GameHistorySort.allCases, id: \.self) { s in
                                    Button(s.rawValue) { sortBy = s }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.arrow.down")
                                    Text(sortBy.rawValue)
                                }
                                .font(AppFonts.tag)
                                .foregroundColor(AppColors.accent)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(filteredGames.enumerated()), id: \.element.id) { index, game in
                                GameHistoryRow(game: game)
                                    .onTapGesture {
                                        navigationPath.append(AppRoute.battleReport(gameData: game))
                                    }
                                    .opacity(isAppeared ? 1 : 0)
                                    .offset(x: isAppeared ? 0 : 30)
                                    .animation(
                                        .easeOut(duration: 0.25).delay(Double(index) * 0.06),
                                        value: isAppeared
                                    )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Game History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadHistory(userId: appViewModel.userId)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isAppeared = true
            }
        }
    }
}

struct GameHistoryRow: View {
    let game: GameHistoryEntry

    var body: some View {
        let isWin = game.winner == game.userId

        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.gameType == "ai" ? "vs AI" : "vs \(game.opponent)")
                    .font(AppFonts.rajdhani(16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text("\(game.boardSize)x\(game.boardSize) | \(game.totalTurns) turns")
                    .font(AppFonts.date)
                    .foregroundColor(AppColors.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(game.completedAt))
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textMuted)

                if isWin {
                    WinTag()
                } else {
                    LossTag()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0, green: 30/255, blue: 60/255).opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.borderLight, lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            if isWin {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.success)
                    .frame(width: 3)
                    .padding(.vertical, 8)
            }
        }
    }

    private func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
