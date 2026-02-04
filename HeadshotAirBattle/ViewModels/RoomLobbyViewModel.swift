import SwiftUI
import FirebaseDatabase

@MainActor
class RoomLobbyViewModel: ObservableObject {
    @Published var player1Name: String?
    @Published var player2Name: String?
    @Published var player1Ready = false
    @Published var player2Ready = false
    @Published var shouldNavigateToGame = false

    private var gameRef: DatabaseReference?
    private var observerHandle: DatabaseHandle?
    private var userId: String = ""

    func listenToGame(gameId: String, userId: String) {
        self.userId = userId
        let db = Database.database(url: "https://airplane-battle-7a3fd-default-rtdb.firebaseio.com")
        gameRef = db.reference().child("activeGames").child(gameId)

        observerHandle = gameRef?.observe(.value) { [weak self] snapshot in
            guard let data = snapshot.value as? [String: Any] else { return }

            Task { @MainActor in
                guard let self = self else { return }

                if let p1 = data["player1"] as? [String: Any] {
                    self.player1Name = p1["nickname"] as? String
                    self.player1Ready = p1["ready"] as? Bool ?? false
                }

                if let p2 = data["player2"] as? [String: Any] {
                    self.player2Name = p2["nickname"] as? String
                    self.player2Ready = p2["ready"] as? Bool ?? false
                }

                let status = data["status"] as? String
                if status == "deploying" || status == "battle" {
                    self.shouldNavigateToGame = true
                }
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
