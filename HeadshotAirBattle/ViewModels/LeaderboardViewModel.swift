import SwiftUI
import FirebaseFirestore

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var selectedTab = "winRate"
    @Published var isLoading = false

    private let db = Firestore.firestore()
    private var cache: [String: (entries: [LeaderboardEntry], timestamp: Date)] = [:]
    private let cacheDuration: TimeInterval = 300 // 5 minutes

    func loadLeaderboard() async {
        // Check cache
        if let cached = cache[selectedTab],
           Date().timeIntervalSince(cached.timestamp) < cacheDuration {
            entries = cached.entries
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await db.collection("users")
                .order(by: selectedTab, descending: true)
                .limit(to: 20)
                .getDocuments()

            entries = snapshot.documents.compactMap { doc in
                let data = doc.data()
                return LeaderboardEntry(
                    userId: doc.documentID,
                    nickname: data["nickname"] as? String ?? "Unknown",
                    totalGames: data["totalGames"] as? Int ?? 0,
                    wins: data["wins"] as? Int ?? 0,
                    winRate: data["winRate"] as? Double ?? 0
                )
            }

            cache[selectedTab] = (entries: entries, timestamp: Date())
        } catch {
            print("[LeaderboardViewModel] Error: \(error.localizedDescription)")
        }
    }
}
