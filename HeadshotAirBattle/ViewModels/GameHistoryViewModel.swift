import SwiftUI
import FirebaseFirestore

@MainActor
class GameHistoryViewModel: ObservableObject {
    @Published var games: [GameHistoryEntry] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()

    func loadHistory(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        // Try loading from Firestore
        do {
            let snapshot = try await db.collection("gameHistory")
                .whereField("userId", isEqualTo: userId)
                .order(by: "completedAt", descending: true)
                .limit(to: 10)
                .getDocuments()

            games = snapshot.documents.compactMap { doc in
                let data = doc.data()
                var entry = GameHistoryEntry(
                    id: doc.documentID,
                    userId: data["userId"] as? String ?? "",
                    gameType: data["gameType"] as? String ?? "ai",
                    opponent: data["opponent"] as? String ?? "AI",
                    winner: data["winner"] as? String ?? "",
                    boardSize: data["boardSize"] as? Int ?? 10,
                    airplaneCount: data["airplaneCount"] as? Int ?? 3,
                    totalTurns: data["totalTurns"] as? Int ?? 0,
                    completedAt: data["completedAt"] as? Double ?? 0,
                    players: data["players"] as? [String] ?? []
                )
                if let statsData = data["playerStats"] as? [String: Any] {
                    entry.playerStats = GameStats(
                        hits: statsData["hits"] as? Int ?? 0,
                        misses: statsData["misses"] as? Int ?? 0,
                        kills: statsData["kills"] as? Int ?? 0
                    )
                }
                if let aiData = data["aiStats"] as? [String: Any] {
                    entry.aiStats = GameStats(
                        hits: aiData["hits"] as? Int ?? 0,
                        misses: aiData["misses"] as? Int ?? 0,
                        kills: aiData["kills"] as? Int ?? 0
                    )
                }
                return entry
            }

            // Cache locally
            saveHistoryLocally()
        } catch {
            print("[GameHistoryViewModel] Error: \(error.localizedDescription)")
            loadHistoryLocally()
        }
    }

    private func saveHistoryLocally() {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: GameConstants.StorageKeys.offlineGameHistory)
        }
    }

    private func loadHistoryLocally() {
        if let data = UserDefaults.standard.data(forKey: GameConstants.StorageKeys.offlineGameHistory),
           let cached = try? JSONDecoder().decode([GameHistoryEntry].self, from: data) {
            games = cached
        }
    }
}
