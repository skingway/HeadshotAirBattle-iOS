import SwiftUI

struct GameHistoryView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = GameHistoryViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else if viewModel.games.isEmpty {
                Text("No games played yet")
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.games) { game in
                            GameHistoryRow(game: game)
                                .onTapGesture {
                                    navigationPath.append(AppRoute.battleReport(gameData: game))
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Game History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadHistory(userId: appViewModel.userId)
        }
    }
}

struct GameHistoryRow: View {
    let game: GameHistoryEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(game.gameType == "ai" ? "vs AI" : "vs \(game.opponent)")
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                    Text(game.winner == game.userId ? "WIN" : "LOSS")
                        .font(.caption.bold())
                        .foregroundColor(game.winner == game.userId ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            (game.winner == game.userId ? Color.green : Color.red).opacity(0.2)
                        )
                        .cornerRadius(4)
                }

                HStack {
                    Text("\(game.boardSize)x\(game.boardSize)")
                    Text("|")
                    Text("\(game.totalTurns) turns")
                    Spacer()
                    Text(formatDate(game.completedAt))
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
