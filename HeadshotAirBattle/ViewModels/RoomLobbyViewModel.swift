import SwiftUI
import FirebaseDatabase

@MainActor
class RoomLobbyViewModel: ObservableObject {
    @Published var player1Name: String?
    @Published var player2Name: String?
    @Published var player1Ready = false
    @Published var player2Ready = false
    @Published var isHost = false
    @Published var amIReady = false
    @Published var shouldNavigateToGame = false
    @Published var boardSize: Int = 10
    @Published var airplaneCount: Int = 3

    private var gameRef: DatabaseReference?
    private var observerHandle: DatabaseHandle?
    private var userId: String = ""
    @Published var myRole: String = ""

    func listenToGame(gameId: String, userId: String) {
        self.userId = userId
        let db = Database.database(url: "https://airplane-battle-7a3fd-default-rtdb.firebaseio.com")
        gameRef = db.reference().child("activeGames").child(gameId)

        observerHandle = gameRef?.observe(.value) { [weak self] snapshot in
            guard let data = snapshot.value as? [String: Any] else { return }

            Task { @MainActor in
                guard let self = self else { return }

                // 读取游戏设置
                self.boardSize = data["boardSize"] as? Int ?? 10
                self.airplaneCount = data["airplaneCount"] as? Int ?? 3

                // 同时检查 "playerReady" 和 "ready" 字段，兼容安卓
                func getReady(_ player: [String: Any]) -> Bool {
                    return player["playerReady"] as? Bool ?? player["ready"] as? Bool ?? false
                }

                // 确定我的角色
                if let p1 = data["player1"] as? [String: Any], p1["id"] as? String == userId {
                    self.myRole = "player1"
                    self.isHost = true
                    self.player1Name = p1["nickname"] as? String
                    self.player1Ready = getReady(p1)
                    self.amIReady = self.player1Ready
                } else {
                    self.myRole = "player2"
                    self.isHost = false
                }

                if let p1 = data["player1"] as? [String: Any] {
                    self.player1Name = p1["nickname"] as? String
                    self.player1Ready = getReady(p1)
                }

                if let p2 = data["player2"] as? [String: Any] {
                    self.player2Name = p2["nickname"] as? String
                    self.player2Ready = getReady(p2)
                    if self.myRole == "player2" {
                        self.amIReady = self.player2Ready
                    }
                }

                // 双方都准备好后，进入部署阶段
                let status = data["status"] as? String
                NSLog("[RoomLobby] Check: p1Ready=\(self.player1Ready), p2Ready=\(self.player2Ready), p2Name=\(self.player2Name ?? "nil"), myRole=\(self.myRole), status=\(status ?? "nil")")

                if self.player1Ready && self.player2Ready && self.player2Name != nil {
                    // 双方都 Ready，设置状态为 deploying
                    if status == "waiting" {
                        NSLog("[RoomLobby] Both ready! Transitioning to deploying...")
                        self.gameRef?.child("status").setValue(GameConstants.OnlineGameStatus.deploying.rawValue)
                    }
                    // 只有双方都 Ready 且状态是 deploying 或 battle 时才跳转
                    if status == "deploying" || status == "battle" {
                        NSLog("[RoomLobby] Both ready and status is \(status ?? ""), navigating to game")
                        self.shouldNavigateToGame = true
                    }
                }
            }
        }
    }

    func toggleReady() {
        guard !myRole.isEmpty else {
            NSLog("[RoomLobby] toggleReady failed: myRole is empty")
            return
        }

        guard gameRef != nil else {
            NSLog("[RoomLobby] toggleReady failed: gameRef is nil")
            return
        }

        amIReady.toggle()
        NSLog("[RoomLobby] Writing ready=\(amIReady) to \(myRole)")

        // 同时写入两个字段，兼容安卓
        let readyData: [String: Any] = ["playerReady": amIReady, "ready": amIReady]
        gameRef?.child(myRole).updateChildValues(readyData) { error, _ in
            if let error = error {
                NSLog("[RoomLobby] Firebase write error: \(error.localizedDescription)")
            } else {
                NSLog("[RoomLobby] Firebase write success for \(self.myRole)")
            }
        }
    }

    func leaveRoom() {
        if let handle = observerHandle {
            gameRef?.removeObserver(withHandle: handle)
        }
        gameRef = nil
    }
}
