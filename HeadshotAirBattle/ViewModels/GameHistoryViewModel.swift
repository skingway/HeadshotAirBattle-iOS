import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class GameHistoryViewModel: ObservableObject {
    @Published var games: [GameHistoryEntry] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()

    func loadHistory(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        let authUid = Auth.auth().currentUser?.uid ?? "nil"
        NSLog("[GameHistoryVM] Loading history: userId=\(userId), authUid=\(authUid)")

        guard !userId.isEmpty else {
            NSLog("[GameHistoryVM] userId is empty, loading locally")
            loadHistoryLocally()
            return
        }

        // Try loading from Firestore
        do {
            // Query with userId filter; try ordered query first, fallback to unordered
            let snapshot: QuerySnapshot
            do {
                snapshot = try await db.collection("gameHistory")
                    .whereField("userId", isEqualTo: userId)
                    .order(by: "completedAt", descending: true)
                    .limit(to: 50)
                    .getDocuments()
            } catch {
                // Fallback: query without ordering (doesn't need composite index)
                NSLog("[GameHistoryVM] Ordered query failed, using fallback: \(error.localizedDescription)")
                snapshot = try await db.collection("gameHistory")
                    .whereField("userId", isEqualTo: userId)
                    .limit(to: 50)
                    .getDocuments()
            }

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
                // Load startedAt for duration calculation
                entry.startedAt = data["startedAt"] as? Double

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
                // Load board data for battle reports
                if let playerBoardDict = data["playerBoardData"] as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: playerBoardDict),
                   let boardData = try? JSONDecoder().decode(BoardData.self, from: jsonData) {
                    entry.playerBoardData = boardData
                }
                if let aiBoardDict = data["aiBoardData"] as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: aiBoardDict),
                   let boardData = try? JSONDecoder().decode(BoardData.self, from: jsonData) {
                    entry.aiBoardData = boardData
                }
                return entry
            }

            // Also try to find games where user is in players array but userId field might differ
            if games.isEmpty {
                do {
                    let playersSnapshot = try await db.collection("gameHistory")
                        .whereField("players", arrayContains: userId)
                        .limit(to: 50)
                        .getDocuments()

                    let additionalGames = playersSnapshot.documents.compactMap { doc -> GameHistoryEntry? in
                        let data = doc.data()
                        // Skip if already in the list
                        guard !games.contains(where: { $0.id == doc.documentID }) else { return nil }
                        var entry = GameHistoryEntry(
                            id: doc.documentID,
                            userId: data["userId"] as? String ?? userId,
                            gameType: data["gameType"] as? String ?? "online",
                            opponent: data["opponent"] as? String ?? "Opponent",
                            winner: data["winner"] as? String ?? "",
                            boardSize: data["boardSize"] as? Int ?? 10,
                            airplaneCount: data["airplaneCount"] as? Int ?? 3,
                            totalTurns: data["totalTurns"] as? Int ?? 0,
                            completedAt: data["completedAt"] as? Double ?? 0,
                            players: data["players"] as? [String] ?? []
                        )
                        entry.startedAt = data["startedAt"] as? Double
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
                    games.append(contentsOf: additionalGames)
                } catch {
                    NSLog("[GameHistoryVM] Players array query failed: \(error.localizedDescription)")
                }
            }

            // Sort by completedAt descending (in case fallback query was used)
            games.sort { $0.completedAt > $1.completedAt }

            NSLog("[GameHistoryVM] Loaded \(games.count) games from Firestore")

            // Cache locally
            saveHistoryLocally()
        } catch {
            NSLog("[GameHistoryVM] Firestore error: \(error)")
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
