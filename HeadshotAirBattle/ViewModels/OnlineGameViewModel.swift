import SwiftUI
import FirebaseDatabase

@MainActor
class OnlineGameViewModel: ObservableObject {
    @Published var gameStatus: GameConstants.OnlineGameStatus = .waiting
    @Published var isDeploymentReady = false
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
    private var myRole: String = "" // "player1" or "player2"
    private var gameRef: DatabaseReference?
    private var observerHandle: DatabaseHandle?
    private var boardSize: Int = 10
    private var airplaneCount: Int = 3

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
                if snapshot.exists() {
                    // 游戏已存在，作为 player2 加入
                    self.myRole = "player2"
                    self.gameRef?.child("player2").setValue([
                        "id": self.userId,
                        "nickname": self.nickname,
                        "connected": true,
                        "ready": false
                    ])
                    // 更新状态为部署阶段
                    self.gameRef?.child("status").setValue(GameConstants.OnlineGameStatus.deploying.rawValue)
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
                            "ready": false
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

        // Determine role
        if let p1 = data["player1"] as? [String: Any], p1["id"] as? String == userId {
            myRole = "player1"
            if let p2 = data["player2"] as? [String: Any] {
                opponentNickname = p2["nickname"] as? String ?? "Opponent"
                opponentDeploymentReady = p2["ready"] as? Bool ?? false
            }
        } else if let p2 = data["player2"] as? [String: Any], p2["id"] as? String == userId {
            myRole = "player2"
            if let p1 = data["player1"] as? [String: Any] {
                opponentNickname = p1["nickname"] as? String ?? "Opponent"
                opponentDeploymentReady = p1["ready"] as? Bool ?? false
            }
        }

        // Check current turn
        if let currentTurn = data["currentTurn"] as? String {
            isMyTurn = currentTurn == myRole
        }

        // Check winner
        if let winner = data["winner"] as? String {
            didWin = winner == userId
        }

        // 如果双方都准备好了，开始战斗
        if gameStatus == .deploying && isDeploymentReady && opponentDeploymentReady {
            gameRef?.child("status").setValue(GameConstants.OnlineGameStatus.battle.rawValue)
            gameRef?.child("currentTurn").setValue("player1")
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
        case .finished:
            gameLog.append("Game over!")
        default:
            break
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
    }

    // 确认部署完成
    func confirmDeployment() {
        guard deploymentHelper.isDeploymentComplete() else { return }

        isDeploymentReady = true

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

            gameRef?.child(myRole).child("airplanes").setValue(airplanesData)
            gameRef?.child(myRole).child("ready").setValue(true)
        }
    }

    // 攻击对手
    func attack(row: Int, col: Int) {
        guard gameStatus == .battle, isMyTurn else { return }

        let attackData: [String: Any] = [
            "row": row,
            "col": col,
            "attacker": myRole,
            "timestamp": ServerValue.timestamp()
        ]

        gameRef?.child("attacks").childByAutoId().setValue(attackData)

        // 切换回合
        let nextTurn = myRole == "player1" ? "player2" : "player1"
        gameRef?.child("currentTurn").setValue(nextTurn)
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
