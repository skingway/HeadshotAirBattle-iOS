import SwiftUI
import FirebaseFirestore
import FirebaseDatabase

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

    func startMatchmaking(mode: String, userId: String, nickname: String, stats: UserProfile?) {
        self.userId = userId
        self.nickname = nickname
        isSearching = true
        timeRemaining = GameConstants.Network.matchmakingTimeout

        // Add to queue
        let entry: [String: Any] = [
            "userId": userId,
            "nickname": nickname,
            "totalGames": stats?.totalGames ?? 0,
            "winRate": stats?.winRate ?? 0,
            "preferredMode": mode,
            "joinedAt": Date().timeIntervalSince1970 * 1000,
            "status": "waiting"
        ]

        db.collection("matchmakingQueue").document(userId).setData(entry)

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

        // Listen for match
        listener = db.collection("matchmakingQueue").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data(),
                      let status = data["status"] as? String,
                      status == "matched",
                      let matchId = data["matchId"] as? String else { return }

                let amIPlayer1 = data["isPlayer1"] as? Bool ?? false

                Task { @MainActor in
                    self.isPlayer1 = amIPlayer1

                    if amIPlayer1 {
                        // 我是 player1，游戏已经创建，直接跳转
                        NSLog("[MatchmakingVM] I am player1, game ready: \(matchId)")
                        self.matchedGameId = matchId
                        self.cleanup()
                    } else {
                        // 我是 player2，需要先加入游戏
                        NSLog("[MatchmakingVM] I am player2, joining game: \(matchId)")
                        await self.joinGameAsPlayer2(gameId: matchId)
                    }
                }
            }

        // Start match checking every 2 seconds
        matchTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.tryFindMatch(mode: mode)
            }
        }
    }

    private func tryFindMatch(mode: String) async {
        do {
            let snapshot = try await db.collection("matchmakingQueue")
                .whereField("status", isEqualTo: "waiting")
                .whereField("preferredMode", isEqualTo: mode)
                .getDocuments()

            let candidates = snapshot.documents.filter { $0.documentID != userId }
            guard let opponent = candidates.first else { return }

            // Atomic match via transaction
            let opponentId = opponent.documentID
            let gameId = "game_\(Int(Date().timeIntervalSince1970 * 1000))_\(Int.random(in: 1000...9999))"

            try await db.runTransaction { transaction, errorPointer in
                let myRef = self.db.collection("matchmakingQueue").document(self.userId)
                let opRef = self.db.collection("matchmakingQueue").document(opponentId)

                let myDoc: DocumentSnapshot
                let opDoc: DocumentSnapshot
                do {
                    myDoc = try transaction.getDocument(myRef)
                    opDoc = try transaction.getDocument(opRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                guard myDoc.data()?["status"] as? String == "waiting",
                      opDoc.data()?["status"] as? String == "waiting" else {
                    return nil
                }

                transaction.updateData(["status": "matched", "matchId": gameId, "isPlayer1": true], forDocument: myRef)
                transaction.updateData(["status": "matched", "matchId": gameId, "isPlayer1": false], forDocument: opRef)

                return nil
            }

            // 创建游戏到 Realtime Database（作为 player1）
            await createGameInRealtimeDatabase(gameId: gameId, mode: mode)

        } catch {
            print("[MatchmakingVM] Match check error: \(error.localizedDescription)")
        }
    }

    /// 在 Realtime Database 创建游戏（和 Android 一致）
    private func createGameInRealtimeDatabase(gameId: String, mode: String) async {
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
                "attacks": [:] as [String: Any],
                "stats": ["hits": 0, "misses": 0, "kills": 0]
            ],
            "currentTurn": NSNull(),
            "turnStartedAt": NSNull(),
            "winner": NSNull()
        ]

        do {
            try await rtdb.reference().child("activeGames").child(gameId).setValue(gameData)
            NSLog("[MatchmakingVM] Game created in Realtime Database: \(gameId)")
        } catch {
            NSLog("[MatchmakingVM] Failed to create game: \(error.localizedDescription)")
        }
    }

    /// 作为 player2 加入游戏（和 Android 的 MultiplayerService.joinGame 一致）
    private func joinGameAsPlayer2(gameId: String) async {
        let player2Data: [String: Any] = [
            "id": userId,
            "nickname": nickname,
            "connected": true,
            "playerReady": false,
            "ready": false,
            "deploymentReady": false,
            "attacks": [:] as [String: Any],
            "stats": ["hits": 0, "misses": 0, "kills": 0]
        ]

        do {
            try await rtdb.reference().child("activeGames").child(gameId).child("player2").setValue(player2Data)
            NSLog("[MatchmakingVM] Joined game as player2: \(gameId)")

            // 加入成功后设置 matchedGameId
            self.matchedGameId = gameId
            self.cleanup()
        } catch {
            NSLog("[MatchmakingVM] Failed to join game: \(error.localizedDescription)")
            self.errorMessage = "Failed to join game"
        }
    }

    func cancelMatchmaking() {
        cleanup()
        db.collection("matchmakingQueue").document(userId).delete()
    }

    func cleanup() {
        timer?.invalidate()
        timer = nil
        matchTimer?.invalidate()
        matchTimer = nil
        listener?.remove()
        listener = nil
        isSearching = false
    }
}
