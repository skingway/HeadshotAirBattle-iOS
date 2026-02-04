import Foundation
import FirebaseFirestore

/// Manages game statistics, history, and leaderboard
class StatisticsService {
    static let shared = StatisticsService()

    private let db = Firestore.firestore()
    private var currentStats: Statistics?

    private init() {}

    // MARK: - Load Statistics

    func loadStatistics(userId: String) async -> Statistics {
        // Load from local first
        var stats = loadLocalStatistics()

        // Try to sync with Firestore
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            if let data = doc.data() {
                let firestoreStats = Statistics(
                    totalGames: data["totalGames"] as? Int ?? 0,
                    wins: data["wins"] as? Int ?? 0,
                    losses: data["losses"] as? Int ?? 0,
                    winRate: data["winRate"] as? Double ?? 0,
                    onlineGames: data["onlineGames"] as? Int,
                    currentStreak: data["currentStreak"] as? Int
                )
                // Use whichever has more games
                if firestoreStats.totalGames > stats.totalGames {
                    stats = firestoreStats
                    saveLocalStatistics(stats)
                }
            }
        } catch {
            print("[StatisticsService] Firestore sync error: \(error.localizedDescription)")
        }

        currentStats = stats
        return stats
    }

    // MARK: - Update Statistics

    func updateStatistics(userId: String, isWinner: Bool, isOnlineGame: Bool = false) async -> Statistics {
        var stats = currentStats ?? loadLocalStatistics()

        stats.totalGames += 1
        if isWinner {
            stats.wins += 1
            stats.currentStreak = (stats.currentStreak ?? 0) + 1
        } else {
            stats.losses += 1
            stats.currentStreak = 0
        }
        stats.winRate = stats.totalGames > 0 ?
            (Double(stats.wins) / Double(stats.totalGames) * 100).rounded(toPlaces: 2) : 0

        if isOnlineGame {
            stats.onlineGames = (stats.onlineGames ?? 0) + 1
        }

        // Save locally first
        saveLocalStatistics(stats)
        currentStats = stats

        // Sync to Firestore in background
        Task {
            do {
                var updateData: [String: Any] = [
                    "totalGames": stats.totalGames,
                    "wins": stats.wins,
                    "losses": stats.losses,
                    "winRate": stats.winRate
                ]
                if let online = stats.onlineGames {
                    updateData["onlineGames"] = online
                }
                if let streak = stats.currentStreak {
                    updateData["currentStreak"] = streak
                }
                try await db.collection("users").document(userId).updateData(updateData)
            } catch {
                print("[StatisticsService] Firestore update error: \(error.localizedDescription)")
            }
        }

        return stats
    }

    // MARK: - Game History

    func saveGameHistory(userId: String, gameData: GameHistoryEntry) async {
        // Save to Firestore
        do {
            let data: [String: Any] = [
                "userId": gameData.userId,
                "gameType": gameData.gameType,
                "opponent": gameData.opponent,
                "winner": gameData.winner,
                "boardSize": gameData.boardSize,
                "airplaneCount": gameData.airplaneCount,
                "totalTurns": gameData.totalTurns,
                "completedAt": gameData.completedAt,
                "players": gameData.players,
                "playerStats": [
                    "hits": gameData.playerStats?.hits ?? 0,
                    "misses": gameData.playerStats?.misses ?? 0,
                    "kills": gameData.playerStats?.kills ?? 0
                ],
                "aiStats": [
                    "hits": gameData.aiStats?.hits ?? 0,
                    "misses": gameData.aiStats?.misses ?? 0,
                    "kills": gameData.aiStats?.kills ?? 0
                ]
            ]
            try await db.collection("gameHistory").addDocument(data: data)
        } catch {
            print("[StatisticsService] History save error: \(error.localizedDescription)")
        }

        // Save locally (keep last 10)
        saveLocalGameHistory(gameData)
    }

    // MARK: - Leaderboard

    func getLeaderboard(type: String) async -> [LeaderboardEntry] {
        do {
            let snapshot = try await db.collection("users")
                .order(by: type, descending: true)
                .limit(to: 20)
                .getDocuments()

            return snapshot.documents.compactMap { doc in
                let data = doc.data()
                return LeaderboardEntry(
                    userId: doc.documentID,
                    nickname: data["nickname"] as? String ?? "Unknown",
                    totalGames: data["totalGames"] as? Int ?? 0,
                    wins: data["wins"] as? Int ?? 0,
                    winRate: data["winRate"] as? Double ?? 0
                )
            }
        } catch {
            print("[StatisticsService] Leaderboard error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Local Storage

    private func loadLocalStatistics() -> Statistics {
        guard let data = UserDefaults.standard.data(forKey: GameConstants.StorageKeys.offlineStatistics),
              let stats = try? JSONDecoder().decode(Statistics.self, from: data) else {
            return Statistics()
        }
        return stats
    }

    private func saveLocalStatistics(_ stats: Statistics) {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: GameConstants.StorageKeys.offlineStatistics)
        }
    }

    private func saveLocalGameHistory(_ entry: GameHistoryEntry) {
        var history = loadLocalGameHistory()
        history.insert(entry, at: 0)
        if history.count > 10 {
            history = Array(history.prefix(10))
        }
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: GameConstants.StorageKeys.offlineGameHistory)
        }
    }

    private func loadLocalGameHistory() -> [GameHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: GameConstants.StorageKeys.offlineGameHistory),
              let history = try? JSONDecoder().decode([GameHistoryEntry].self, from: data) else {
            return []
        }
        return history
    }
}

// MARK: - Double Rounding Extension

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
