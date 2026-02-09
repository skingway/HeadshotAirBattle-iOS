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
    @Published var debugStatus: String = "init"
    private var readyCheckTimer: Timer?

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
                self.debugStatus = "p1=\(self.player1Ready) p2=\(self.player2Ready) s=\(status ?? "?") r=\(self.myRole)"
                NSLog("[RoomLobby] Check: p1Ready=\(self.player1Ready), p2Ready=\(self.player2Ready), p2Name=\(self.player2Name ?? "nil"), myRole=\(self.myRole), status=\(status ?? "nil")")

                if self.player1Ready && self.player2Ready && self.player2Name != nil {
                    // 双方都 Ready，设置状态为 deploying 并导航
                    if status == "waiting" {
                        NSLog("[RoomLobby] Both ready! Transitioning to deploying and navigating...")
                        self.gameRef?.child("status").setValue(GameConstants.OnlineGameStatus.deploying.rawValue)
                        // Navigate immediately instead of waiting for the next observer callback
                        self.shouldNavigateToGame = true
                    } else if status == "deploying" || status == "battle" {
                        NSLog("[RoomLobby] Both ready and status is \(status ?? ""), navigating to game")
                        self.shouldNavigateToGame = true
                    }
                }
            }
        }

        startReadyCheckPolling()
    }

    func startReadyCheckPolling() {
        readyCheckTimer?.invalidate()
        readyCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, !self.shouldNavigateToGame else {
                    self?.readyCheckTimer?.invalidate()
                    self?.readyCheckTimer = nil
                    return
                }

                self.gameRef?.getData { error, snapshot in
                    guard error == nil,
                          let data = snapshot?.value as? [String: Any] else { return }

                    Task { @MainActor in
                        guard !self.shouldNavigateToGame else { return }

                        let p1 = data["player1"] as? [String: Any]
                        let p2 = data["player2"] as? [String: Any]
                        let status = data["status"] as? String

                        let p1Ready = p1?["playerReady"] as? Bool ?? p1?["ready"] as? Bool ?? false
                        let p2Ready = p2?["playerReady"] as? Bool ?? p2?["ready"] as? Bool ?? false
                        let p2Name = p2?["nickname"] as? String

                        NSLog("[RoomLobby] Poll: p1Ready=\(p1Ready), p2Ready=\(p2Ready), p2Name=\(p2Name ?? "nil"), status=\(status ?? "nil")")

                        if p1Ready && p2Ready && p2Name != nil {
                            if status == "waiting" {
                                NSLog("[RoomLobby] Poll: Both ready! Setting deploying and navigating")
                                self.gameRef?.child("status").setValue(GameConstants.OnlineGameStatus.deploying.rawValue)
                                self.shouldNavigateToGame = true
                            } else if status == "deploying" || status == "battle" {
                                NSLog("[RoomLobby] Poll: Both ready, status=\(status ?? ""). Navigating!")
                                self.shouldNavigateToGame = true
                            }
                        }
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

        guard let ref = gameRef else {
            NSLog("[RoomLobby] toggleReady failed: gameRef is nil")
            return
        }

        NSLog("[RoomLobby] toggleReady: amIReady=\(amIReady), myRole=\(myRole), p1Ready=\(player1Ready), p2Ready=\(player2Ready)")
        amIReady.toggle()
        let newReady = amIReady
        NSLog("[RoomLobby] Writing ready=\(newReady) to \(myRole)")

        // 同时写入两个字段，兼容安卓
        let readyData: [String: Any] = ["playerReady": newReady, "ready": newReady]
        ref.child(myRole).updateChildValues(readyData) { [weak self] error, _ in
            if let error = error {
                NSLog("[RoomLobby] Firebase write error: \(error.localizedDescription)")
                return
            }
            NSLog("[RoomLobby] Firebase write success for \(self?.myRole ?? "?")")

            // CRITICAL: After write succeeds, directly read game state and navigate
            // This bypasses the observer which may have timing issues
            guard newReady else { return } // Only check when setting ready=true
            ref.getData { error, snapshot in
                guard error == nil,
                      let data = snapshot?.value as? [String: Any] else {
                    NSLog("[RoomLobby] Direct check: getData failed: \(error?.localizedDescription ?? "no data")")
                    return
                }
                Task { @MainActor in
                    guard let self = self, !self.shouldNavigateToGame else { return }

                    let p1 = data["player1"] as? [String: Any]
                    let p2 = data["player2"] as? [String: Any]
                    let status = data["status"] as? String
                    let p1Ready = p1?["playerReady"] as? Bool ?? p1?["ready"] as? Bool ?? false
                    let p2Ready = p2?["playerReady"] as? Bool ?? p2?["ready"] as? Bool ?? false
                    let p2Name = p2?["nickname"] as? String

                    NSLog("[RoomLobby] Direct check after write: p1Ready=\(p1Ready), p2Ready=\(p2Ready), p2Name=\(p2Name ?? "nil"), status=\(status ?? "nil")")

                    if p1Ready && p2Ready && p2Name != nil {
                        if status == "waiting" {
                            NSLog("[RoomLobby] Direct check: Both ready! Setting deploying and navigating")
                            ref.child("status").setValue("deploying")
                        }
                        NSLog("[RoomLobby] Direct check: NAVIGATING to game!")
                        self.shouldNavigateToGame = true
                    }
                }
            }
        }
    }

    func leaveRoom() {
        readyCheckTimer?.invalidate()
        readyCheckTimer = nil
        if let handle = observerHandle {
            gameRef?.removeObserver(withHandle: handle)
        }
        observerHandle = nil
        gameRef = nil
    }
}
