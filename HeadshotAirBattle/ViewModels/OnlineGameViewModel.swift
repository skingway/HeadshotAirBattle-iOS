import SwiftUI
import UIKit
import FirebaseDatabase

@MainActor
class OnlineGameViewModel: ObservableObject {
    @Published var gameStatus: GameConstants.OnlineGameStatus = .waiting
    @Published var isPlayerReady = false         // 玩家是否点击了Ready按钮
    @Published var opponentReady = false         // 对手是否Ready
    @Published var isDeploymentReady = false     // 部署是否完成确认
    @Published var opponentDeploymentReady = false
    @Published var didWin = false
    @Published var opponentNickname = ""
    @Published var isMyTurn = false
    @Published var gameLog: [String] = []

    // Helpers for sub-views
    let deploymentHelper = GameViewModel()
    let battleHelper = GameViewModel()

    private var gameId: String = ""
    private var userId: String = ""
    private var nickname: String = ""
    @Published var myRole: String = "" // "player1" or "player2"
    private var gameRef: DatabaseReference?
    private var observerHandle: DatabaseHandle?
    private var boardSize: Int = 10
    private var airplaneCount: Int = 3

    // Opponent's board data for attack calculation
    private var opponentBoard: BoardManager?
    private var opponentUserId: String = ""

    // Track attacks for display
    @Published var myAttacks: [String: String] = [:]  // "row,col" -> "hit"/"miss"/"kill"
    @Published var opponentAttacks: [String: String] = [:]  // attacks on my board

    func joinAndListen(gameId: String, userId: String, nickname: String) {
        self.gameId = gameId
        self.userId = userId
        self.nickname = nickname

        // 初始化部署视图的 GameViewModel
        deploymentHelper.setup(
            difficulty: "easy",
            mode: "online",
            boardSize: boardSize,
            airplaneCount: airplaneCount,
            userId: userId
        )

        let db = Database.database(url: "https://airplane-battle-7a3fd-default-rtdb.firebaseio.com")
        gameRef = db.reference().child("activeGames").child(gameId)

        // 创建或加入游戏
        setupGame()

        observerHandle = gameRef?.observe(.value) { [weak self] snapshot in
            guard let data = snapshot.value as? [String: Any] else { return }

            Task { @MainActor in
                guard let self = self else { return }
                self.processGameState(data)
            }
        }
    }

    private func setupGame() {
        gameRef?.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }

            Task { @MainActor in
                if snapshot.exists(), let data = snapshot.value as? [String: Any] {
                    // 游戏已存在，检查我是 player1 还是 player2
                    if let p1 = data["player1"] as? [String: Any], p1["id"] as? String == self.userId {
                        // 我是 player1（创建者）
                        self.myRole = "player1"
                        // 更新连接状态
                        self.gameRef?.child("player1").child("connected").setValue(true)
                    } else if let p2 = data["player2"] as? [String: Any], p2["id"] as? String == self.userId {
                        // 我是 player2（已加入）
                        self.myRole = "player2"
                        self.gameRef?.child("player2").child("connected").setValue(true)
                    } else {
                        // 我是新加入的 player2
                        self.myRole = "player2"
                        self.gameRef?.child("player2").setValue([
                            "id": self.userId,
                            "nickname": self.nickname,
                            "connected": true,
                            "playerReady": false,
                            "ready": false,  // 兼容安卓
                            "deploymentReady": false
                        ])
                    }
                    // 状态保持 waiting，等待双方都点击 Ready 后再进入部署阶段
                } else {
                    // 创建新游戏，作为 player1
                    self.myRole = "player1"
                    let gameData: [String: Any] = [
                        "status": GameConstants.OnlineGameStatus.waiting.rawValue,
                        "boardSize": self.boardSize,
                        "airplaneCount": self.airplaneCount,
                        "createdAt": ServerValue.timestamp(),
                        "player1": [
                            "id": self.userId,
                            "nickname": self.nickname,
                            "connected": true,
                            "playerReady": false,
                            "ready": false,  // 兼容安卓
                            "deploymentReady": false
                        ]
                    ]
                    self.gameRef?.setValue(gameData)
                }
            }
        }
    }

    private func processGameState(_ data: [String: Any]) {
        if let statusStr = data["status"] as? String,
           let status = GameConstants.OnlineGameStatus(rawValue: statusStr) {
            let oldStatus = gameStatus
            gameStatus = status

            // 状态变化时的处理
            if oldStatus != status {
                handleStatusChange(from: oldStatus, to: status, data: data)
            }
        }

        // Determine role and track ready states
        // 同时检查 "playerReady" 和 "ready" 字段，兼容安卓
        func getReady(_ player: [String: Any]) -> Bool {
            return player["playerReady"] as? Bool ?? player["ready"] as? Bool ?? false
        }
        func getDeploymentReady(_ player: [String: Any]) -> Bool {
            // 检查 deploymentReady 或者 (ready && board存在)
            if player["deploymentReady"] as? Bool == true {
                return true
            }
            // 兼容安卓：如果 ready=true 且有 board 数据，也算部署完成
            if player["ready"] as? Bool == true && player["board"] != nil {
                return true
            }
            return false
        }

        if let p1 = data["player1"] as? [String: Any], p1["id"] as? String == userId {
            myRole = "player1"
            isPlayerReady = getReady(p1)
            isDeploymentReady = getDeploymentReady(p1)  // 也从 Firebase 读取自己的部署状态
            if let p2 = data["player2"] as? [String: Any] {
                opponentNickname = p2["nickname"] as? String ?? "Opponent"
                opponentReady = getReady(p2)
                opponentDeploymentReady = getDeploymentReady(p2)
                opponentUserId = p2["id"] as? String ?? ""
            }
        } else if let p2 = data["player2"] as? [String: Any], p2["id"] as? String == userId {
            myRole = "player2"
            isPlayerReady = getReady(p2)
            isDeploymentReady = getDeploymentReady(p2)  // 也从 Firebase 读取自己的部署状态
            if let p1 = data["player1"] as? [String: Any] {
                opponentNickname = p1["nickname"] as? String ?? "Opponent"
                opponentReady = getReady(p1)
                opponentDeploymentReady = getDeploymentReady(p1)
                opponentUserId = p1["id"] as? String ?? ""
            }
        }

        // 双方都点击Ready后，进入部署阶段
        NSLog("[OnlineGame] Check: status=\(gameStatus.rawValue), me=\(isPlayerReady), opponent=\(opponentReady), myRole=\(myRole)")
        if gameStatus == .waiting && isPlayerReady && opponentReady {
            NSLog("[OnlineGame] Both ready! Transitioning to deploying...")
            gameLog.append("Both ready! Starting deployment...")
            gameRef?.child("status").setValue(GameConstants.OnlineGameStatus.deploying.rawValue)
        }

        // Check current turn - Android uses userId, not role
        if let currentTurn = data["currentTurn"] as? String {
            isMyTurn = currentTurn == userId
            NSLog("[OnlineGame] Turn check: currentTurn=\(currentTurn), userId=\(userId), isMyTurn=\(isMyTurn)")
        }

        // Check winner
        if let winner = data["winner"] as? String {
            didWin = winner == userId
        }

        // Sync attacks in battle mode
        if gameStatus == .battle {
            syncAttacksFromFirebase(data: data)
        }

        // 如果双方都部署完成，开始战斗
        NSLog("[OnlineGame] DeployCheck: status=\(gameStatus.rawValue), myDeploy=\(isDeploymentReady), opDeploy=\(opponentDeploymentReady)")
        if gameStatus == .deploying && isDeploymentReady && opponentDeploymentReady {
            NSLog("[OnlineGame] Both deployed! Starting battle...")
            gameLog.append("Both deployed! Starting battle...")

            // Get player1's userId for currentTurn (Android uses userId, not role)
            if let p1 = data["player1"] as? [String: Any], let p1Id = p1["id"] as? String {
                gameRef?.child("status").setValue(GameConstants.OnlineGameStatus.battle.rawValue)
                gameRef?.child("currentTurn").setValue(p1Id)
                gameRef?.child("turnStartedAt").setValue(ServerValue.timestamp())
                NSLog("[OnlineGame] Battle started, first turn: \(p1Id)")
            }
        }
    }

    private func handleStatusChange(from oldStatus: GameConstants.OnlineGameStatus, to newStatus: GameConstants.OnlineGameStatus, data: [String: Any]) {
        switch newStatus {
        case .deploying:
            // 进入部署阶段
            gameLog.append("Game started! Deploy your airplanes.")
        case .battle:
            // 进入战斗阶段，初始化战斗视图
            setupBattlePhase(data: data)
            gameLog.append("Battle begins!")
            // 播放背景音乐
            AudioService.shared.playBGM()
        case .finished:
            gameLog.append("Game over!")
            // 停止背景音乐，播放胜负音效和震动
            AudioService.shared.stopBGM()
            if didWin {
                AudioService.shared.playVictory()
            } else {
                AudioService.shared.playDefeat()
            }
            // 保存游戏记录和统计数据
            saveOnlineGameResult(data: data)
        default:
            break
        }
    }

    /// 检查前5次攻击是否全部命中（用于先知成就）
    private func checkFirst5AllHit() -> Bool {
        // 获取按时间排序的前5次攻击
        let sortedAttacks = myAttacks.sorted { $0.key < $1.key }.prefix(5)
        guard sortedAttacks.count >= 5 else { return false }

        // 检查是否全部命中（hit 或 kill）
        return sortedAttacks.allSatisfy { _, result in
            result == "hit" || result == "kill"
        }
    }

    /// 保存在线游戏结果到历史记录和统计数据
    private func saveOnlineGameResult(data: [String: Any]) {
        guard !userId.isEmpty else { return }

        // 获取双方的统计数据
        let myPlayerData = data[myRole] as? [String: Any]
        let opponentRole = myRole == "player1" ? "player2" : "player1"
        let opponentData = data[opponentRole] as? [String: Any]

        let myStats: GameStats
        if let statsDict = myPlayerData?["stats"] as? [String: Any] {
            myStats = GameStats(
                hits: statsDict["hits"] as? Int ?? 0,
                misses: statsDict["misses"] as? Int ?? 0,
                kills: statsDict["kills"] as? Int ?? 0
            )
        } else {
            // 从本地 attacks 计算
            var hits = 0, misses = 0, kills = 0
            for (_, result) in myAttacks {
                switch result {
                case "hit": hits += 1
                case "miss": misses += 1
                case "kill": hits += 1; kills += 1
                default: break
                }
            }
            myStats = GameStats(hits: hits, misses: misses, kills: kills)
        }

        let opponentStats: GameStats
        if let statsDict = opponentData?["stats"] as? [String: Any] {
            opponentStats = GameStats(
                hits: statsDict["hits"] as? Int ?? 0,
                misses: statsDict["misses"] as? Int ?? 0,
                kills: statsDict["kills"] as? Int ?? 0
            )
        } else {
            opponentStats = GameStats()
        }

        let winner = data["winner"] as? String ?? ""

        // 构建游戏历史记录
        let historyEntry = GameHistoryEntry(
            id: nil,
            userId: userId,
            gameType: "online",
            opponent: opponentNickname,
            winner: winner,
            boardSize: boardSize,
            airplaneCount: airplaneCount,
            totalTurns: myAttacks.count,
            completedAt: Date().timeIntervalSince1970 * 1000,
            players: [userId, opponentUserId],
            playerStats: myStats,
            aiStats: opponentStats
        )

        Task {
            // 更新统计数据（包含 Leaderboard）
            let updatedStats = await StatisticsService.shared.updateStatistics(
                userId: userId,
                isWinner: didWin,
                isOnlineGame: true
            )

            // 检查成就
            await MainActor.run {
                // 构建 GameResult 用于游戏结束成就检查
                let gameResult = GameResult(
                    winner: didWin ? "player" : "opponent",
                    totalTurns: myAttacks.count,
                    playerStats: myStats,
                    aiStats: opponentStats,
                    comebackWin: false, // 在线游戏暂不检测
                    first5AllHit: checkFirst5AllHit(),
                    boardSize: boardSize,
                    airplaneCount: airplaneCount,
                    gameType: .online,
                    opponent: opponentNickname
                )

                // 检查游戏结束成就（如神枪手、闪电战等）
                AchievementService.shared.checkGameEndAchievements(gameResult: gameResult, userStats: updatedStats)

                // 检查统计成就（如战术家、连胜等）
                AchievementService.shared.checkStatsAchievements(userStats: updatedStats)
            }

            // 保存游戏历史
            await StatisticsService.shared.saveGameHistory(
                userId: userId,
                gameData: historyEntry
            )

            NSLog("[OnlineGame] Game result saved: winner=\(winner), didWin=\(didWin), myTurns=\(myAttacks.count)")
        }
    }

    private func setupBattlePhase(data: [String: Any]) {
        battleHelper.setup(
            difficulty: "easy",
            mode: "online",
            boardSize: boardSize,
            airplaneCount: airplaneCount,
            userId: userId
        )

        // 复制部署的飞机到战斗视图
        if let playerBoard = deploymentHelper.playerBoard {
            battleHelper.playerBoard = playerBoard
        }

        // Parse opponent's board data for attack calculation
        let opponentRole = myRole == "player1" ? "player2" : "player1"
        if let opponent = data[opponentRole] as? [String: Any] {
            opponentUserId = opponent["id"] as? String ?? ""

            // Create opponent's board from their data
            if let boardData = opponent["board"] as? [String: Any],
               let airplanesData = boardData["airplanes"] as? [[String: Any]] {
                opponentBoard = BoardManager(size: boardSize, airplaneCount: airplaneCount)
                for airplaneData in airplanesData {
                    if let id = airplaneData["id"] as? Int,
                       let headRow = airplaneData["headRow"] as? Int,
                       let headCol = airplaneData["headCol"] as? Int,
                       let directionStr = airplaneData["direction"] as? String,
                       let direction = GameConstants.Direction(rawValue: directionStr) {
                        let airplane = Airplane(headRow: headRow, headCol: headCol, direction: direction, id: id)
                        _ = opponentBoard?.addAirplane(airplane)
                    }
                }
                NSLog("[OnlineGame] Opponent board loaded with \(opponentBoard?.airplanes.count ?? 0) airplanes")
            }
        }

        // Sync existing attacks from Firebase
        syncAttacksFromFirebase(data: data)
    }

    private func syncAttacksFromFirebase(data: [String: Any]) {
        // Sync my attacks (stored under my role)
        if let myPlayer = data[myRole] as? [String: Any],
           let attacksDict = myPlayer["attacks"] as? [String: [String: Any]] {
            for (_, attackData) in attacksDict {
                if let row = attackData["row"] as? Int,
                   let col = attackData["col"] as? Int,
                   let result = attackData["result"] as? String {
                    let key = "\(row),\(col)"
                    myAttacks[key] = result
                }
            }
        }

        // Sync opponent's attacks on my board
        let opponentRole = myRole == "player1" ? "player2" : "player1"
        if let opponent = data[opponentRole] as? [String: Any],
           let attacksDict = opponent["attacks"] as? [String: [String: Any]] {
            let previousCount = opponentAttacks.count
            for (_, attackData) in attacksDict {
                if let row = attackData["row"] as? Int,
                   let col = attackData["col"] as? Int,
                   let result = attackData["result"] as? String {
                    let key = "\(row),\(col)"
                    if opponentAttacks[key] == nil {
                        // New attack from opponent - play haptic feedback
                        opponentAttacks[key] = result
                    }
                }
            }
            // If there were new attacks, play a notification haptic
            if opponentAttacks.count > previousCount {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
        }
    }

    // 玩家点击 Ready 按钮
    func clickReady() {
        // 确保 myRole 已设置
        guard !myRole.isEmpty else {
            NSLog("[OnlineGame] clickReady failed: myRole is empty")
            gameLog.append("Error: Role not set")
            return
        }

        guard gameRef != nil else {
            NSLog("[OnlineGame] clickReady failed: gameRef is nil")
            gameLog.append("Error: Not connected")
            return
        }

        isPlayerReady = true
        gameLog.append("You clicked Ready (\(myRole))")
        NSLog("[OnlineGame] Writing ready=true to \(myRole)")

        // 同时写入两个字段，兼容安卓
        let readyData: [String: Any] = ["playerReady": true, "ready": true]
        gameRef?.child(myRole).updateChildValues(readyData) { [weak self] error, _ in
            if let error = error {
                NSLog("[OnlineGame] Firebase write error: \(error.localizedDescription)")
                Task { @MainActor in
                    self?.gameLog.append("Error: \(error.localizedDescription)")
                }
            } else {
                NSLog("[OnlineGame] Firebase write success")
            }
        }
    }

    // 确认部署完成
    func confirmDeployment() {
        guard deploymentHelper.isDeploymentComplete() else { return }
        guard !myRole.isEmpty else {
            NSLog("[OnlineGame] confirmDeployment failed: myRole is empty")
            return
        }

        isDeploymentReady = true
        gameLog.append("Deployment confirmed (\(myRole))")

        // 保存飞机位置到 Firebase
        if let board = deploymentHelper.playerBoard {
            let airplanesData = board.airplanes.map { airplane -> [String: Any] in
                return [
                    "id": airplane.id,
                    "headRow": airplane.headRow,
                    "headCol": airplane.headCol,
                    "direction": airplane.direction.rawValue
                ]
            }

            // 同时保存到多个位置，兼容安卓
            let playerRef = gameRef?.child(myRole)

            // 保存飞机数据（两种格式）
            playerRef?.child("airplanes").setValue(airplanesData)
            playerRef?.child("board").setValue(["airplanes": airplanesData])

            // 设置部署完成标志（两个字段）
            playerRef?.updateChildValues([
                "deploymentReady": true,
                "ready": true
            ]) { error, _ in
                if let error = error {
                    NSLog("[OnlineGame] Deployment save error: \(error.localizedDescription)")
                } else {
                    NSLog("[OnlineGame] Deployment saved successfully")
                }
            }
        }
    }

    // 攻击对手
    func attack(row: Int, col: Int) {
        NSLog("[OnlineGame] Attack attempt: row=\(row), col=\(col), status=\(gameStatus.rawValue), isMyTurn=\(isMyTurn), myRole=\(myRole)")

        guard gameStatus == .battle else {
            NSLog("[OnlineGame] Attack failed: not in battle status")
            gameLog.append("Not in battle mode")
            return
        }

        guard isMyTurn else {
            NSLog("[OnlineGame] Attack failed: not my turn")
            gameLog.append("Not your turn")
            return
        }

        guard !myRole.isEmpty else {
            NSLog("[OnlineGame] Attack failed: myRole is empty")
            return
        }

        // Check if already attacked this cell
        let key = "\(row),\(col)"
        if myAttacks[key] != nil {
            NSLog("[OnlineGame] Attack failed: cell already attacked")
            gameLog.append("Already attacked this cell!")
            return
        }

        guard let opponentBoard = opponentBoard else {
            NSLog("[OnlineGame] Attack failed: opponent board not loaded")
            gameLog.append("Error: opponent board not loaded")
            return
        }

        // Calculate attack result using opponent's board
        let result: String
        let coord = "\(CoordinateSystem.indexToLetter(col))\(row + 1)"

        if let airplane = opponentBoard.getAirplaneAt(row: row, col: col) {
            // Hit an airplane - record the hit
            airplane.hits.insert("\(row),\(col)")

            // Check if this is the head (kill)
            if airplane.headRow == row && airplane.headCol == col {
                airplane.isDestroyed = true
                result = "kill"
                gameLog.append("Attack \(coord) - KILL!")
                NSLog("[OnlineGame] KILL at \(coord)")
                AudioService.shared.playSFX(for: .kill)
            } else {
                result = "hit"
                gameLog.append("Attack \(coord) - HIT!")
                NSLog("[OnlineGame] HIT at \(coord)")
                AudioService.shared.playSFX(for: .hit)
            }
        } else {
            result = "miss"
            gameLog.append("Attack \(coord) - MISS")
            NSLog("[OnlineGame] MISS at \(coord)")
            AudioService.shared.playSFX(for: .miss)
        }

        // Record attack locally
        myAttacks[key] = result

        // Save attack to Firebase under my role (like Android does)
        let attackData: [String: Any] = [
            "row": row,
            "col": col,
            "result": result,
            "timestamp": ServerValue.timestamp()
        ]

        gameRef?.child(myRole).child("attacks").childByAutoId().setValue(attackData) { [weak self] error, _ in
            if let error = error {
                NSLog("[OnlineGame] Attack save error: \(error.localizedDescription)")
            } else {
                NSLog("[OnlineGame] Attack saved successfully")
            }
        }

        // Update stats
        updateStats(result: result)

        // Check for win condition
        if checkWinCondition() {
            // I won!
            gameRef?.updateChildValues([
                "status": GameConstants.OnlineGameStatus.finished.rawValue,
                "winner": userId,
                "completedAt": ServerValue.timestamp()
            ])
            gameLog.append("🎉 YOU WIN!")
            return
        }

        // Switch turn to opponent's userId (not role!)
        gameRef?.child("currentTurn").setValue(opponentUserId)
        gameRef?.child("turnStartedAt").setValue(ServerValue.timestamp())

        // 暂时设置不是我的回合（等待 Firebase 更新）
        isMyTurn = false
    }

    private func updateStats(result: String) {
        // Get current stats and update
        gameRef?.child(myRole).child("stats").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            var stats = snapshot.value as? [String: Int] ?? ["hits": 0, "misses": 0, "kills": 0]

            if result == "hit" || result == "kill" {
                stats["hits"] = (stats["hits"] ?? 0) + 1
                if result == "kill" {
                    stats["kills"] = (stats["kills"] ?? 0) + 1
                }
            } else if result == "miss" {
                stats["misses"] = (stats["misses"] ?? 0) + 1
            }

            Task { @MainActor in
                self.gameRef?.child(self.myRole).child("stats").setValue(stats)
            }
        }
    }

    private func checkWinCondition() -> Bool {
        // Check if all opponent's airplane heads have been hit
        guard let opponentBoard = opponentBoard else { return false }

        for airplane in opponentBoard.airplanes {
            let headKey = "\(airplane.headRow),\(airplane.headCol)"
            if myAttacks[headKey] != "kill" {
                return false
            }
        }
        return true
    }

    // 投降
    func surrender() {
        guard !myRole.isEmpty else { return }

        let opponentRole = myRole == "player1" ? "player2" : "player1"

        // 设置对手为胜者
        gameRef?.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let data = snapshot.value as? [String: Any],
                  let opponent = data[opponentRole] as? [String: Any],
                  let opponentId = opponent["id"] as? String else { return }

            Task { @MainActor in
                self?.gameRef?.updateChildValues([
                    "status": GameConstants.OnlineGameStatus.finished.rawValue,
                    "winner": opponentId,
                    "endReason": "surrender"
                ])
                self?.gameLog.append("You surrendered")
            }
        }
    }

    func leaveGame() {
        if !myRole.isEmpty {
            gameRef?.child(myRole).child("connected").setValue(false)
        }
        cleanup()
    }

    func cleanup() {
        if let handle = observerHandle {
            gameRef?.removeObserver(withHandle: handle)
        }
        observerHandle = nil
        gameRef = nil
    }
}
