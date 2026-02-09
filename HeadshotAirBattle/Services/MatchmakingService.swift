import Foundation
import FirebaseFirestore
import FirebaseDatabase

/// Manages matchmaking queue using Firestore + RTDB pendingMatches
class MatchmakingService {
    static let shared = MatchmakingService()

    private let db = Firestore.firestore()
    private let rtdb = Database.database(url: "https://airplane-battle-7a3fd-default-rtdb.firebaseio.com")
    private var firestoreListener: ListenerRegistration?
    private var pendingMatchHandle: DatabaseHandle?
    private var pendingMatchRef: DatabaseReference?
    private var matchCheckTimer: Timer?
    private var timeoutTimer: Timer?
    private var userId: String?
    private var isInQueue = false
    var onMatchFound: ((String) -> Void)?

    private init() {}

    // MARK: - Join Queue

    func joinQueue(userId: String, nickname: String, totalGames: Int, winRate: Double, mode: String) async throws {
        self.userId = userId

        // Clean up stale data first
        try? await db.collection("matchmakingQueue").document(userId).delete()
        try? await rtdb.reference().child("pendingMatches").child(userId).removeValue()

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
        isInQueue = true

        // Start listening for match (both Firestore doc and RTDB pendingMatches)
        startMatchListening(userId: userId)

        // Start periodic match checking
        startMatchChecking(mode: mode)

        // Start timeout
        startTimeout()

        NSLog("[MatchmakingService] Joined queue, userId=\(userId)")
    }

    // MARK: - Leave Queue

    func leaveQueue() async {
        guard let userId = userId else { return }

        try? await db.collection("matchmakingQueue").document(userId).delete()
        try? await rtdb.reference().child("pendingMatches").child(userId).removeValue()
        isInQueue = false
        cleanup()
    }

    // MARK: - Match Listening

    private func startMatchListening(userId: String) {
        // 1. Listen on own Firestore queue doc
        firestoreListener = db.collection("matchmakingQueue").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data(),
                      let status = data["status"] as? String,
                      status == "matched",
                      let matchId = data["matchId"] as? String else { return }

                NSLog("[MatchmakingService] Match found via Firestore doc: \(matchId)")
                self?.handleMatchFound(matchId)
            }

        // 2. Listen on RTDB pendingMatches/{userId} for when opponent creates match
        let ref = rtdb.reference().child("pendingMatches").child(userId)
        pendingMatchRef = ref
        pendingMatchHandle = ref.observe(.value) { [weak self] snapshot in
            guard snapshot.exists(),
                  let data = snapshot.value as? [String: Any],
                  let gameId = data["gameId"] as? String else { return }

            NSLog("[MatchmakingService] Match found via pendingMatches: \(gameId)")
            // Clean up the pending match entry
            ref.removeValue()
            self?.handleMatchFound(gameId)
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
        guard let userId = userId, isInQueue else { return }

        do {
            // Check own status first
            let myDoc = try await db.collection("matchmakingQueue").document(userId).getDocument()
            guard let myData = myDoc.data(),
                  myData["status"] as? String == "waiting" else { return }

            let snapshot = try await db.collection("matchmakingQueue")
                .whereField("status", isEqualTo: "waiting")
                .whereField("preferredMode", isEqualTo: mode)
                .getDocuments()

            let candidates = snapshot.documents.filter { $0.documentID != userId }
            guard let opponent = candidates.first else { return }

            let opponentId = opponent.documentID

            // Deterministic arbitration: only the player with smaller userId creates the match
            // This prevents both players from simultaneously creating separate games
            if userId > opponentId {
                NSLog("[MatchmakingService] Skipping - opponent \(opponentId) has priority (smaller userId)")
                return
            }

            NSLog("[MatchmakingService] I have priority (smaller userId) - creating match")

            let myNickname = myData["nickname"] as? String ?? "Player"

            // Create game in RTDB
            let createdGameId = try await MultiplayerService.shared.createGame(
                hostId: userId,
                hostNickname: myNickname,
                gameType: "quickMatch"
            )

            // Update our own Firestore doc (we have permission for this)
            try await db.collection("matchmakingQueue").document(userId).updateData([
                "status": "matched",
                "matchId": createdGameId
            ])

            // Notify opponent via RTDB pendingMatches (can't write opponent's Firestore doc)
            try await rtdb.reference().child("pendingMatches").child(opponentId).setValue([
                "gameId": createdGameId,
                "matchedBy": userId,
                "timestamp": Date().millisecondsSince1970
            ])

            // Join the opponent to the game in RTDB
            let opNickname = opponent.data()["nickname"] as? String ?? "Opponent"
            try await MultiplayerService.shared.joinGame(gameId: createdGameId, userId: opponentId, nickname: opNickname)

            NSLog("[MatchmakingService] Match created: \(createdGameId)")

        } catch {
            NSLog("[MatchmakingService] Match check error: \(error.localizedDescription)")
        }
    }

    // MARK: - Match Found

    private func handleMatchFound(_ gameId: String) {
        guard isInQueue else { return }
        isInQueue = false
        cleanup()
        onMatchFound?(gameId)
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
        firestoreListener?.remove()
        firestoreListener = nil
        if let handle = pendingMatchHandle {
            pendingMatchRef?.removeObserver(withHandle: handle)
        }
        pendingMatchHandle = nil
        pendingMatchRef = nil
        matchCheckTimer?.invalidate()
        matchCheckTimer = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}
