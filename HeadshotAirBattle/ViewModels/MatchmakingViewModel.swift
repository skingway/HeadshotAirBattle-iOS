import SwiftUI
import FirebaseFirestore
import FirebaseDatabase
import FirebaseAuth

@MainActor
class MatchmakingViewModel: ObservableObject {
    @Published var timerText = "60"
    @Published var matchedGameId: String?
    @Published var errorMessage: String?
    @Published var isSearching = false
    @Published var isPlayer1 = false  // 是否是创建游戏的人

    private var timer: Timer?
    private var matchTimer: Timer?
    private var timeRemaining: TimeInterval = 60
    private let db = Firestore.firestore()
    private let rtdb = Database.database(url: "https://airplane-battle-7a3fd-default-rtdb.firebaseio.com")
    private var userId: String = ""
    private var nickname: String = ""
    private var listener: ListenerRegistration?
    private var pendingMatchHandle: DatabaseHandle?
    private var pendingMatchRef: DatabaseReference?

    func startMatchmaking(mode: String, userId: String, nickname: String, stats: UserProfile?) {
        self.userId = userId
        self.nickname = nickname
        isSearching = true
        matchedGameId = nil
        timeRemaining = GameConstants.Network.matchmakingTimeout

        let authUid = Auth.auth().currentUser?.uid ?? "nil"
        NSLog("[MatchmakingVM] Starting matchmaking: userId=\(userId), authUid=\(authUid), mode=\(mode)")

        // CRITICAL: pendingMatches RTDB security rule requires auth.uid == $userId
        // If appViewModel.userId != auth.uid, reads will fail silently!
        if userId != authUid {
            NSLog("[MatchmakingVM] WARNING: userId mismatch! Using authUid instead")
            self.userId = authUid
        }

        // Clean up stale pendingMatches from previous sessions BEFORE setting up listener
        rtdb.reference().child("pendingMatches").child(self.userId).removeValue()

        // Add to queue (use self.userId which may have been corrected to authUid)
        let effectiveUserId = self.userId
        let entry: [String: Any] = [
            "userId": effectiveUserId,
            "nickname": nickname,
            "totalGames": stats?.totalGames ?? 0,
            "winRate": stats?.winRate ?? 0,
            "preferredMode": mode,
            "joinedAt": Date().timeIntervalSince1970 * 1000,
            "status": "waiting"
        ]

        db.collection("matchmakingQueue").document(effectiveUserId).setData(entry)

        // Start countdown timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.timeRemaining -= 1
                self.timerText = "\(Int(self.timeRemaining))"
                if self.timeRemaining <= 0 {
                    self.cancelMatchmaking()
                    self.errorMessage = "Matchmaking timed out"
                }
            }
        }

        // Listen for match on own Firestore doc
        listener = db.collection("matchmakingQueue").document(effectiveUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      self.matchedGameId == nil,
                      let data = snapshot?.data(),
                      let status = data["status"] as? String,
                      status == "matched",
                      let matchId = data["matchId"] as? String else { return }

                NSLog("[MatchmakingVM] Match found via Firestore doc: \(matchId)")
                Task { @MainActor in
                    await self.determineRoleAndJoin(gameId: matchId)
                }
            }

        // Listen for match on RTDB pendingMatches (for when opponent creates the match)
        startPendingMatchListener(userId: effectiveUserId)

        // Start match checking every 2 seconds
        matchTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.tryFindMatch(mode: mode)
            }
        }
    }

    /// Listen on RTDB pendingMatches/{userId} for matches created by opponents
    private func startPendingMatchListener(userId: String) {
        let ref = rtdb.reference().child("pendingMatches").child(userId)
        pendingMatchRef = ref
        pendingMatchHandle = ref.observe(.value) { [weak self] snapshot in
            guard snapshot.exists(),
                  let data = snapshot.value as? [String: Any],
                  let gameId = data["gameId"] as? String else { return }

            NSLog("[MatchmakingVM] Match found via pendingMatches LISTENER: \(gameId)")
            // Clean up the pending match entry
            ref.removeValue()
            Task { @MainActor in
                guard self?.matchedGameId == nil else {
                    NSLog("[MatchmakingVM] Already matched, ignoring pendingMatches")
                    return
                }
                await self?.determineRoleAndJoin(gameId: gameId)
            }
        }
    }

    private func tryFindMatch(mode: String) async {
        guard matchedGameId == nil else { return }

        do {
            let snapshot = try await db.collection("matchmakingQueue")
                .whereField("status", isEqualTo: "waiting")
                .whereField("preferredMode", isEqualTo: mode)
                .getDocuments()

            let candidates = snapshot.documents.filter { $0.documentID != userId }
            NSLog("[MatchmakingVM] tryFindMatch: \(candidates.count) candidates (total docs: \(snapshot.documents.count))")
            guard let opponent = candidates.first else {
                // No waiting candidates — opponent may have already matched us.
                // Check recently matched players who might have created a game for us.
                await checkMatchedOpponents()
                await pollPendingMatches()
                return
            }

            let opponentId = opponent.documentID

            // Deterministic arbitration: only the player with the lexicographically
            // smaller userId creates the match. This prevents both players from
            // simultaneously creating duplicate games.
            if userId > opponentId {
                // Opponent has priority to create the match.
                // Check if they've already created it by reading their Firestore doc.
                let opDoc = try await db.collection("matchmakingQueue").document(opponentId).getDocument()
                if let opData = opDoc.data(),
                   opData["status"] as? String == "matched",
                   let matchId = opData["matchId"] as? String {
                    NSLog("[MatchmakingVM] Found match via opponent's Firestore doc: \(matchId)")
                    await determineRoleAndJoin(gameId: matchId)
                    return
                }
                // Also try pendingMatches as secondary fallback
                await pollPendingMatches()
                return
            }

            // Verify both still waiting
            let myDoc = try await db.collection("matchmakingQueue").document(userId).getDocument()
            let opDoc = try await db.collection("matchmakingQueue").document(opponentId).getDocument()

            guard myDoc.data()?["status"] as? String == "waiting",
                  opDoc.data()?["status"] as? String == "waiting" else {
                NSLog("[MatchmakingVM] Player no longer waiting, skipping")
                return
            }

            let gameId = "game_\(Int(Date().timeIntervalSince1970 * 1000))_\(Int.random(in: 1000...9999))"
            NSLog("[MatchmakingVM] Creating game: \(gameId) against opponent: \(opponentId)")

            // Create game in RTDB first (does NOT navigate)
            let created = await createGameInRealtimeDatabase(gameId: gameId, mode: mode)
            guard created else { return }

            // Update own Firestore doc (we have permission for this)
            try await db.collection("matchmakingQueue").document(userId).updateData([
                "status": "matched",
                "matchId": gameId
            ])

            // Notify opponent via RTDB pendingMatches (cross-platform compatible with Android)
            try await rtdb.reference().child("pendingMatches").child(opponentId).setValue([
                "gameId": gameId,
                "matchedBy": userId,
                "timestamp": ServerValue.timestamp()
            ])

            NSLog("[MatchmakingVM] Match created: \(gameId), notified opponent: \(opponentId)")

            // NOW navigate - all writes are complete, opponent has been notified
            self.matchedGameId = gameId
            self.cleanup()

        } catch {
            NSLog("[MatchmakingVM] Match check error: \(error)")
            // Even if Firestore query fails (e.g. missing composite index),
            // still check pendingMatches in case opponent already matched us
            await pollPendingMatches()
        }
    }

    /// Check if any recently-matched opponent created a game that we should join
    private func checkMatchedOpponents() async {
        guard matchedGameId == nil else { return }
        do {
            // Find players who recently matched (they updated their own doc to "matched")
            let snapshot = try await db.collection("matchmakingQueue")
                .whereField("status", isEqualTo: "matched")
                .getDocuments()

            for doc in snapshot.documents {
                guard let matchId = doc.data()["matchId"] as? String,
                      let matchedBy = doc.data()["userId"] as? String,
                      matchedBy != userId else { continue }

                // Check if this game's opponent is us by reading the RTDB game
                let gameSnapshot = try await rtdb.reference().child("activeGames").child(matchId).getData()
                guard let gameData = gameSnapshot.value as? [String: Any] else { continue }

                // Check if player2 is null (opponent is waiting for someone to join)
                // and we're not already in the game
                let p1 = gameData["player1"] as? [String: Any]
                let p2 = gameData["player2"] as? [String: Any]

                if p1?["id"] as? String != userId && p2 == nil {
                    NSLog("[MatchmakingVM] Found unjoined game via matched opponent: \(matchId)")
                    await determineRoleAndJoin(gameId: matchId)
                    return
                }
            }
        } catch {
            NSLog("[MatchmakingVM] checkMatchedOpponents error: \(error)")
        }
    }

    /// Fallback: manually poll RTDB pendingMatches in case the real-time listener missed data
    private func pollPendingMatches() async {
        guard matchedGameId == nil else { return }
        do {
            let snapshot = try await rtdb.reference().child("pendingMatches").child(userId).getData()
            guard let data = snapshot.value as? [String: Any],
                  let gameId = data["gameId"] as? String else { return }

            NSLog("[MatchmakingVM] pendingMatches POLL found match: \(gameId)")
            try await rtdb.reference().child("pendingMatches").child(userId).removeValue()
            await determineRoleAndJoin(gameId: gameId)
        } catch {
            NSLog("[MatchmakingVM] pendingMatches poll error: \(error)")
        }
    }

    /// Determine our role by checking RTDB game data, then join if needed
    private func determineRoleAndJoin(gameId: String) async {
        guard matchedGameId == nil else {
            NSLog("[MatchmakingVM] Already matched, skipping determineRoleAndJoin for \(gameId)")
            return
        }
        do {
            let snapshot = try await rtdb.reference().child("activeGames").child(gameId).getData()
            guard let data = snapshot.value as? [String: Any] else {
                // Game doesn't exist yet in RTDB - we need to create it (we are the initiator)
                NSLog("[MatchmakingVM] Game not yet in RTDB, I am player1, creating game via MultiplayerService: \(gameId)")
                self.isPlayer1 = true
                let created = await createGameInRealtimeDatabase(gameId: gameId, mode: "standard")
                if created {
                    self.matchedGameId = gameId
                    self.cleanup()
                }
                return
            }

            // Game exists - check if we are player1
            if let p1 = data["player1"] as? [String: Any], p1["id"] as? String == userId {
                NSLog("[MatchmakingVM] I am player1, game ready: \(gameId)")
                self.isPlayer1 = true
                // Set MultiplayerService state so OnlineGameViewModel can use it
                MultiplayerService.shared.setGameState(gameId: gameId, role: "player1")
                self.matchedGameId = gameId
                self.cleanup()
            } else if let p2 = data["player2"] as? [String: Any], p2["id"] as? String == userId {
                // We are already player2 (Android may have joined us)
                NSLog("[MatchmakingVM] I am already player2, game ready: \(gameId)")
                self.isPlayer1 = false
                MultiplayerService.shared.setGameState(gameId: gameId, role: "player2")
                self.matchedGameId = gameId
                self.cleanup()
            } else {
                // Game exists but we are not in it yet - join as player2
                NSLog("[MatchmakingVM] Game exists, joining as player2 via MultiplayerService: \(gameId)")
                self.isPlayer1 = false
                try await MultiplayerService.shared.joinGame(gameId: gameId, userId: userId, nickname: nickname)
                self.matchedGameId = gameId
                self.cleanup()
            }
        } catch {
            NSLog("[MatchmakingVM] Error determining role: \(error.localizedDescription)")
            self.errorMessage = "Failed to join game"
        }
    }

    /// 在 Realtime Database 创建游戏（和 Android 一致）
    /// Returns true if game was created successfully, false otherwise.
    /// Does NOT set matchedGameId or cleanup - caller is responsible for that.
    private func createGameInRealtimeDatabase(gameId: String, mode: String) async -> Bool {
        let gameData: [String: Any] = [
            "gameId": gameId,
            "gameType": "quickMatch",
            "status": "waiting",
            "mode": mode,
            "boardSize": 10,
            "airplaneCount": 3,
            "createdAt": ServerValue.timestamp(),
            "player1": [
                "id": userId,
                "nickname": nickname,
                "connected": true,
                "playerReady": false,
                "ready": false,
                "deploymentReady": false,
                "stats": ["hits": 0, "misses": 0, "kills": 0]
            ],
            "player2": NSNull(),
            "currentTurn": NSNull(),
            "turnStartedAt": NSNull(),
            "winner": NSNull()
        ]

        do {
            try await rtdb.reference().child("activeGames").child(gameId).setValue(gameData)
            // Set MultiplayerService state so OnlineGameViewModel can use it
            MultiplayerService.shared.setGameState(gameId: gameId, role: "player1")
            NSLog("[MatchmakingVM] Game created in RTDB + MultiplayerService state set: \(gameId)")
            return true
        } catch {
            NSLog("[MatchmakingVM] Failed to create game: \(error.localizedDescription)")
            self.errorMessage = "Failed to create game"
            return false
        }
    }

    // joinGameAsPlayer2 removed — now using MultiplayerService.shared.joinGame() in determineRoleAndJoin

    func cancelMatchmaking() {
        cleanup()
        db.collection("matchmakingQueue").document(userId).delete()
        // Clean up any pending match entry (like Android's leaveQueue)
        rtdb.reference().child("pendingMatches").child(userId).removeValue()
    }

    func cleanup() {
        timer?.invalidate()
        timer = nil
        matchTimer?.invalidate()
        matchTimer = nil
        listener?.remove()
        listener = nil
        if let handle = pendingMatchHandle {
            pendingMatchRef?.removeObserver(withHandle: handle)
        }
        pendingMatchHandle = nil
        pendingMatchRef = nil
        isSearching = false
    }
}
