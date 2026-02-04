import Foundation
import FirebaseFirestore

/// Manages matchmaking queue using Firestore
class MatchmakingService {
    static let shared = MatchmakingService()

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var matchCheckTimer: Timer?
    private var timeoutTimer: Timer?
    private var userId: String?
    var onMatchFound: ((String) -> Void)?

    private init() {}

    // MARK: - Join Queue

    func joinQueue(userId: String, nickname: String, totalGames: Int, winRate: Double, mode: String) async throws {
        self.userId = userId

        let entry: [String: Any] = [
            "userId": userId,
            "nickname": nickname,
            "totalGames": totalGames,
            "winRate": winRate,
            "preferredMode": mode,
            "joinedAt": Date().millisecondsSince1970,
            "status": "waiting"
        ]

        try await db.collection("matchmakingQueue").document(userId).setData(entry)

        // Start listening for match
        startMatchListening(userId: userId)

        // Start periodic match checking
        startMatchChecking(mode: mode)

        // Start timeout
        startTimeout()
    }

    // MARK: - Leave Queue

    func leaveQueue() async {
        guard let userId = userId else { return }

        try? await db.collection("matchmakingQueue").document(userId).delete()
        cleanup()
    }

    // MARK: - Match Listening

    private func startMatchListening(userId: String) {
        listener = db.collection("matchmakingQueue").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data(),
                      let status = data["status"] as? String,
                      status == "matched",
                      let matchId = data["matchId"] as? String else { return }

                self?.onMatchFound?(matchId)
                self?.cleanup()
            }
    }

    // MARK: - Match Checking

    private func startMatchChecking(mode: String) {
        matchCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task {
                await self?.tryFindMatch(mode: mode)
            }
        }
    }

    private func tryFindMatch(mode: String) async {
        guard let userId = userId else { return }

        do {
            let snapshot = try await db.collection("matchmakingQueue")
                .whereField("status", isEqualTo: "waiting")
                .whereField("preferredMode", isEqualTo: mode)
                .getDocuments()

            let candidates = snapshot.documents.filter { $0.documentID != userId }
            guard let opponent = candidates.first else { return }

            let opponentId = opponent.documentID
            let gameId = "game_\(Int(Date().millisecondsSince1970))_\(Int.random(in: 1000...9999))"

            // Create game
            let multiplayerService = MultiplayerService.shared
            let myDoc = try await db.collection("matchmakingQueue").document(userId).getDocument()
            let myNickname = myDoc.data()?["nickname"] as? String ?? "Player"

            let createdGameId = try await multiplayerService.createGame(
                hostId: userId,
                hostNickname: myNickname,
                gameType: "quickMatch"
            )

            // Atomic update both queue entries
            try await db.runTransaction { [self] transaction, _ in
                let myRef = self.db.collection("matchmakingQueue").document(userId)
                let opRef = self.db.collection("matchmakingQueue").document(opponentId)

                let myDoc = try transaction.getDocument(myRef)
                let opDoc = try transaction.getDocument(opRef)

                guard myDoc.data()?["status"] as? String == "waiting",
                      opDoc.data()?["status"] as? String == "waiting" else {
                    return nil
                }

                transaction.updateData(["status": "matched", "matchId": createdGameId], forDocument: myRef)
                transaction.updateData(["status": "matched", "matchId": createdGameId], forDocument: opRef)

                return nil
            }

            // Join the opponent to the game
            let opNickname = opponent.data()["nickname"] as? String ?? "Opponent"
            try await multiplayerService.joinGame(gameId: createdGameId, userId: opponentId, nickname: opNickname)

        } catch {
            print("[MatchmakingService] Match check error: \(error.localizedDescription)")
        }
    }

    // MARK: - Timeout

    private func startTimeout() {
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: GameConstants.Network.matchmakingTimeout, repeats: false) { [weak self] _ in
            Task {
                await self?.leaveQueue()
            }
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        listener?.remove()
        listener = nil
        matchCheckTimer?.invalidate()
        matchCheckTimer = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}
