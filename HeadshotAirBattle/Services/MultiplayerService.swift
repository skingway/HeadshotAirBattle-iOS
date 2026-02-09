import Foundation
import FirebaseDatabase

/// Manages real-time game synchronization via Firebase Realtime Database
class MultiplayerService {
    static let shared = MultiplayerService()

    private let db = Database.database(url: "https://airplane-battle-7a3fd-default-rtdb.firebaseio.com")
    private var gameRef: DatabaseReference?
    private var observerHandle: DatabaseHandle?
    private var presenceRef: DatabaseReference?
    private var disconnectRef: DatabaseReference?

    private(set) var currentGameId: String?
    private(set) var myRole: String? // "player1" or "player2"
    private var stateListeners: [(OnlineGameState) -> Void] = []

    private init() {}

    /// Set game state externally (e.g., from MatchmakingViewModel when game was created/joined outside MultiplayerService)
    func setGameState(gameId: String, role: String) {
        self.currentGameId = gameId
        self.myRole = role
    }

    // MARK: - Create Game

    func createGame(hostId: String, hostNickname: String, gameType: String = "privateRoom",
                    mode: String = "standard", boardSize: Int = 10, airplaneCount: Int = 3,
                    roomCode: String? = nil) async throws -> String {
        let gameId = "game_\(Int(Date().millisecondsSince1970))_\(Int.random(in: 1000...9999))"

        let player = GamePlayer(id: hostId, nickname: hostNickname)

        let gameData: [String: Any] = [
            "gameId": gameId,
            "gameType": gameType,
            "roomCode": roomCode as Any,
            "status": "waiting",
            "mode": mode,
            "boardSize": boardSize,
            "airplaneCount": airplaneCount,
            "createdAt": Date().millisecondsSince1970,
            "player1": [
                "id": player.id,
                "nickname": player.nickname,
                "playerReady": false,
                "ready": false,  // 兼容安卓
                "deploymentReady": false,
                "connected": true,
                "stats": ["hits": 0, "misses": 0, "kills": 0]
            ],
            "player2": NSNull(),
            "currentTurn": NSNull(),
            "turnStartedAt": NSNull(),
            "winner": NSNull()
        ]

        let ref = db.reference().child("activeGames").child(gameId)
        try await ref.setValue(gameData)

        currentGameId = gameId
        myRole = "player1"

        return gameId
    }

    // MARK: - Join Game

    func joinGame(gameId: String, userId: String, nickname: String) async throws {
        let ref = db.reference().child("activeGames").child(gameId)

        let playerData: [String: Any] = [
            "id": userId,
            "nickname": nickname,
            "playerReady": false,
            "ready": false,  // 兼容安卓
            "deploymentReady": false,
            "connected": true,
            "stats": ["hits": 0, "misses": 0, "kills": 0]
        ]

        try await ref.child("player2").setValue(playerData)
        // Set status to deploying (like Android's MultiplayerService.joinGame)
        try await ref.child("status").setValue("deploying")

        currentGameId = gameId
        myRole = "player2"
    }

    // MARK: - Listen to Game State

    func listenToGame(gameId: String, callback: @escaping (OnlineGameState) -> Void) {
        let ref = db.reference().child("activeGames").child(gameId)
        gameRef = ref

        observerHandle = ref.observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else { return }

            // Parse game state
            let state = OnlineGameState(
                gameId: data["gameId"] as? String ?? gameId,
                gameType: data["gameType"] as? String ?? "quickMatch",
                roomCode: data["roomCode"] as? String,
                status: data["status"] as? String ?? "waiting",
                mode: data["mode"] as? String ?? "standard",
                boardSize: data["boardSize"] as? Int ?? 10,
                airplaneCount: data["airplaneCount"] as? Int ?? 3,
                createdAt: data["createdAt"] as? Double ?? 0,
                player1: Self.parsePlayer(data["player1"]),
                player2: Self.parsePlayer(data["player2"]),
                currentTurn: data["currentTurn"] as? String,
                turnStartedAt: data["turnStartedAt"] as? Double,
                winner: data["winner"] as? String,
                completedAt: data["completedAt"] as? Double,
                battleStartedAt: data["battleStartedAt"] as? Double
            )

            callback(state)
        }
    }

    private static func parsePlayer(_ value: Any?) -> GamePlayer? {
        guard let dict = value as? [String: Any],
              let id = dict["id"] as? String,
              let nickname = dict["nickname"] as? String else {
            return nil
        }

        var player = GamePlayer(id: id, nickname: nickname)
        player.ready = dict["ready"] as? Bool ?? false
        player.connected = dict["connected"] as? Bool ?? true

        if let statsDict = dict["stats"] as? [String: Any] {
            player.stats = GameStats(
                hits: statsDict["hits"] as? Int ?? 0,
                misses: statsDict["misses"] as? Int ?? 0,
                kills: statsDict["kills"] as? Int ?? 0
            )
        }

        // Parse board if present
        if let boardDict = dict["board"] as? [String: Any],
           let airplanesArray = boardDict["airplanes"] as? [[String: Any]] {
            let airplanes = airplanesArray.compactMap { dict -> AirplaneData? in
                guard let id = dict["id"] as? Int,
                      let headRow = dict["headRow"] as? Int,
                      let headCol = dict["headCol"] as? Int,
                      let direction = dict["direction"] as? String else { return nil }
                return AirplaneData(id: id, headRow: headRow, headCol: headCol, direction: direction)
            }
            player.board = PlayerBoard(airplanes: airplanes)
        }

        // Parse attacks if present (dictionary format with push keys)
        if let attacksDict = dict["attacks"] as? [String: [String: Any]] {
            var attacks: [String: OnlineAttackRecord] = [:]
            for (key, attackData) in attacksDict {
                if let row = attackData["row"] as? Int,
                   let col = attackData["col"] as? Int,
                   let result = attackData["result"] as? String,
                   let timestamp = attackData["timestamp"] as? Double {
                    attacks[key] = OnlineAttackRecord(row: row, col: col, result: result, timestamp: timestamp)
                }
            }
            player.attacks = attacks
        }

        return player
    }

    // MARK: - Presence

    func setupPresence(gameId: String, role: String) {
        let connectedRef = db.reference(withPath: ".info/connected")
        let playerConnectedRef = db.reference()
            .child("activeGames").child(gameId).child(role).child("connected")

        connectedRef.observe(.value) { [weak self] snapshot in
            guard let connected = snapshot.value as? Bool, connected else { return }

            // Set connected = true
            playerConnectedRef.setValue(true)

            // On disconnect, set connected = false
            playerConnectedRef.onDisconnectSetValue(false)
            self?.disconnectRef = playerConnectedRef
        }
    }

    // MARK: - Submit Board

    func submitBoard(gameId: String, role: String, airplanes: [AirplaneData]) async throws {
        let ref = db.reference().child("activeGames").child(gameId).child(role)

        let airplanesData = airplanes.map { airplane -> [String: Any] in
            return [
                "id": airplane.id,
                "headRow": airplane.headRow,
                "headCol": airplane.headCol,
                "direction": airplane.direction
            ]
        }

        try await ref.child("board").setValue(["airplanes": airplanesData])
        try await ref.child("ready").setValue(true)

        // Check if both players are ready to start battle
        try await checkBothReady(gameId: gameId)
    }

    private func checkBothReady(gameId: String) async throws {
        let ref = db.reference().child("activeGames").child(gameId)
        let snapshot = try await ref.getData()

        guard let data = snapshot.value as? [String: Any],
              let p1 = data["player1"] as? [String: Any],
              let p2 = data["player2"] as? [String: Any] else { return }

        let p1Ready = p1["ready"] as? Bool ?? false
        let p2Ready = p2["ready"] as? Bool ?? false
        let p1HasBoard = p1["board"] != nil
        let p2HasBoard = p2["board"] != nil

        if p1Ready && p2Ready && p1HasBoard && p2HasBoard {
            // Start battle - player1 goes first
            let p1Id = p1["id"] as? String ?? ""
            try await ref.updateChildValues([
                "status": "battle",
                "currentTurn": p1Id,
                "turnStartedAt": Date().millisecondsSince1970,
                "battleStartedAt": Date().millisecondsSince1970
            ])
        }
    }

    // MARK: - Attack

    func attack(gameId: String, role: String, row: Int, col: Int, result: String) async throws {
        let ref = db.reference().child("activeGames").child(gameId)
        let attacksRef = ref.child(role).child("attacks")

        // Use push key (Firebase dictionary format, not array)
        let attackData: [String: Any] = [
            "row": row,
            "col": col,
            "result": result,
            "timestamp": Date().millisecondsSince1970
        ]
        try await attacksRef.childByAutoId().setValue(attackData)

        // Update stats
        let statsRef = ref.child(role).child("stats")
        let snapshot = try await statsRef.getData()
        var stats = snapshot.value as? [String: Any] ?? ["hits": 0, "misses": 0, "kills": 0]

        if result == "hit" || result == "kill" {
            stats["hits"] = (stats["hits"] as? Int ?? 0) + 1
            if result == "kill" {
                stats["kills"] = (stats["kills"] as? Int ?? 0) + 1
            }
        } else if result == "miss" {
            stats["misses"] = (stats["misses"] as? Int ?? 0) + 1
        }
        try await statsRef.setValue(stats)

        // Switch turn
        let opponentRole = role == "player1" ? "player2" : "player1"
        let opponentSnapshot = try await ref.child(opponentRole).child("id").getData()
        let opponentId = opponentSnapshot.value as? String ?? ""

        try await ref.updateChildValues([
            "currentTurn": opponentId,
            "turnStartedAt": Date().millisecondsSince1970
        ])
    }

    // MARK: - End Game

    func endGame(gameId: String, winnerId: String) async throws {
        let ref = db.reference().child("activeGames").child(gameId)
        try await ref.updateChildValues([
            "status": "finished",
            "winner": winnerId,
            "completedAt": Date().millisecondsSince1970
        ])
    }

    // MARK: - Leave Game

    func leaveGame() {
        guard let gameId = currentGameId, let role = myRole else { return }

        let ref = db.reference().child("activeGames").child(gameId).child(role)
        ref.child("connected").setValue(false)

        cleanup()
    }

    // MARK: - Cleanup

    func cleanup() {
        if let handle = observerHandle {
            gameRef?.removeObserver(withHandle: handle)
        }
        observerHandle = nil
        gameRef = nil
        disconnectRef = nil
        currentGameId = nil
        myRole = nil
        stateListeners.removeAll()
    }
}
