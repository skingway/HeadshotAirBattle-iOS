import SwiftUI
import FirebaseFirestore

@MainActor
class MatchmakingViewModel: ObservableObject {
    @Published var timerText = "60"
    @Published var matchedGameId: String?
    @Published var errorMessage: String?
    @Published var isSearching = false

    private var timer: Timer?
    private var matchTimer: Timer?
    private var timeRemaining: TimeInterval = 60
    private let db = Firestore.firestore()
    private var userId: String = ""
    private var listener: ListenerRegistration?

    func startMatchmaking(mode: String, userId: String, nickname: String, stats: UserProfile?) {
        self.userId = userId
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
                guard let data = snapshot?.data(),
                      let status = data["status"] as? String,
                      status == "matched",
                      let matchId = data["matchId"] as? String else { return }

                Task { @MainActor in
                    self?.matchedGameId = matchId
                    self?.cleanup()
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

                transaction.updateData(["status": "matched", "matchId": gameId], forDocument: myRef)
                transaction.updateData(["status": "matched", "matchId": gameId], forDocument: opRef)

                return nil
            }
        } catch {
            print("[MatchmakingVM] Match check error: \(error.localizedDescription)")
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
