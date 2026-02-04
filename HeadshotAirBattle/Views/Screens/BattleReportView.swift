import SwiftUI

struct BattleReportView: View {
    @Binding var navigationPath: NavigationPath
    let gameData: GameHistoryEntry

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Result
                    Text(gameData.winner == gameData.userId ? "VICTORY" : "DEFEAT")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(gameData.winner == gameData.userId ? .green : .red)

                    // Game info
                    VStack(spacing: 12) {
                        InfoRow(label: "Mode", value: "\(gameData.boardSize)x\(gameData.boardSize)")
                        InfoRow(label: "Airplanes", value: "\(gameData.airplaneCount)")
                        InfoRow(label: "Total Turns", value: "\(gameData.totalTurns)")
                        InfoRow(label: "Opponent", value: gameData.opponent)
                        InfoRow(label: "Type", value: gameData.gameType == "ai" ? "vs AI" : "Online")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // Player stats
                    if let stats = gameData.playerStats {
                        VStack(spacing: 12) {
                            Text("Your Stats")
                                .font(.headline)
                                .foregroundColor(.cyan)
                            InfoRow(label: "Hits", value: "\(stats.hits)")
                            InfoRow(label: "Misses", value: "\(stats.misses)")
                            InfoRow(label: "Kills", value: "\(stats.kills)")
                            let total = stats.hits + stats.misses
                            if total > 0 {
                                InfoRow(label: "Accuracy", value: String(format: "%.1f%%", Double(stats.hits) / Double(total) * 100))
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // AI stats
                    if let aiStats = gameData.aiStats {
                        VStack(spacing: 12) {
                            Text("Opponent Stats")
                                .font(.headline)
                                .foregroundColor(.orange)
                            InfoRow(label: "Hits", value: "\(aiStats.hits)")
                            InfoRow(label: "Misses", value: "\(aiStats.misses)")
                            InfoRow(label: "Kills", value: "\(aiStats.kills)")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Battle Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
    }
}
