import SwiftUI
import FirebaseDatabase

@MainActor
class OnlineGameViewModel: ObservableObject {
    @Published var gameStatus: GameConstants.OnlineGameStatus = .waiting
    @Published var isDeploymentReady = false
    @Published var didWin = false
    @Published var opponentNickname = ""

    // Helpers for sub-views (will be fully implemented in Phase 4)
    let deploymentHelper = GameViewModel()
    let battleHelper = GameViewModel()

    private var gameId: String = ""
    private var userId: String = ""
    private var myRole: String = "" // "player1" or "player2"
    private var gameRef: DatabaseReference?
    private var observerHandle: DatabaseHandle?

    func joinAndListen(gameId: String, userId: String, nickname: String) {
        self.gameId = gameId
        self.userId = userId

        let db = Database.database(url: "https://airplane-battle-7a3fd-default-rtdb.firebaseio.com")
        gameRef = db.reference().child("activeGames").child(gameId)

        observerHandle = gameRef?.observe(.value) { [weak self] snapshot in
            guard let data = snapshot.value as? [String: Any] else { return }

            Task { @MainActor in
                guard let self = self else { return }
                self.processGameState(data)
            }
        }
    }

    private func processGameState(_ data: [String: Any]) {
        if let statusStr = data["status"] as? String,
           let status = GameConstants.OnlineGameStatus(rawValue: statusStr) {
            gameStatus = status
        }

        // Determine role
        if let p1 = data["player1"] as? [String: Any], p1["id"] as? String == userId {
            myRole = "player1"
            if let p2 = data["player2"] as? [String: Any] {
                opponentNickname = p2["nickname"] as? String ?? "Opponent"
            }
        } else {
            myRole = "player2"
            if let p1 = data["player1"] as? [String: Any] {
                opponentNickname = p1["nickname"] as? String ?? "Opponent"
            }
        }

        // Check winner
        if let winner = data["winner"] as? String {
            didWin = winner == userId
        }
    }

    func leaveGame() {
        if let myRole = myRole.isEmpty ? nil : myRole {
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
