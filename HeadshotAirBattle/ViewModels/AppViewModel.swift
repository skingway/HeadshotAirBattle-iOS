import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AppViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var userProfile: UserProfile?
    @Published var isOfflineMode = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func initialize() async {
        isLoading = true
        defer { isLoading = false }

        // Try Firebase anonymous auth with 5s timeout
        do {
            let result = try await withTimeout(seconds: 5) {
                try await Auth.auth().signInAnonymously()
            }
            let userId = result.user.uid
            await loadOrCreateProfile(userId: userId)
            isAuthenticated = true
        } catch {
            print("[AppViewModel] Firebase auth failed: \(error.localizedDescription)")
            loadOfflineProfile()
            isOfflineMode = true
            isAuthenticated = true
        }
    }

    private func loadOrCreateProfile(userId: String) async {
        let docRef = db.collection("users").document(userId)

        do {
            let document = try await docRef.getDocument()
            if document.exists, let data = document.data() {
                userProfile = UserProfile(
                    userId: userId,
                    nickname: data["nickname"] as? String ?? generateNickname()
                )
                userProfile?.totalGames = data["totalGames"] as? Int ?? 0
                userProfile?.wins = data["wins"] as? Int ?? 0
                userProfile?.losses = data["losses"] as? Int ?? 0
                userProfile?.winRate = data["winRate"] as? Double ?? 0
                userProfile?.onlineGames = data["onlineGames"] as? Int
                userProfile?.createdAt = data["createdAt"] as? Double ?? Date().timeIntervalSince1970 * 1000
                userProfile?.nicknameChangedAt = data["nicknameChangedAt"] as? Double
                userProfile?.selectedBackground = data["selectedBackground"] as? String
            } else {
                // Create new profile
                let nickname = generateNickname()
                let profile = UserProfile(userId: userId, nickname: nickname)
                let profileData: [String: Any] = [
                    "userId": profile.userId,
                    "nickname": profile.nickname,
                    "createdAt": profile.createdAt,
                    "totalGames": 0,
                    "wins": 0,
                    "losses": 0,
                    "winRate": 0
                ]
                try await docRef.setData(profileData)
                userProfile = profile
            }
            saveProfileLocally()
        } catch {
            print("[AppViewModel] Firestore error: \(error.localizedDescription)")
            loadOfflineProfile()
        }
    }

    private func loadOfflineProfile() {
        if let data = UserDefaults.standard.data(forKey: GameConstants.StorageKeys.offlineUserProfile),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
        } else {
            // Create a local-only profile
            let userId = UUID().uuidString
            let profile = UserProfile(userId: userId, nickname: generateNickname())
            userProfile = profile
            saveProfileLocally()
        }
    }

    private func saveProfileLocally() {
        guard let profile = userProfile,
              let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: GameConstants.StorageKeys.offlineUserProfile)
    }

    func generateNickname() -> String {
        let adjectives = [
            "Swift", "Brave", "Silent", "Fierce", "Shadow",
            "Storm", "Iron", "Steel", "Thunder", "Crimson",
            "Golden", "Silver", "Dark", "Frost", "Flame"
        ]
        let nouns = [
            "Pilot", "Eagle", "Hawk", "Falcon", "Dragon",
            "Wolf", "Tiger", "Phoenix", "Viper", "Knight",
            "Ace", "Star", "Jet", "Wing", "Arrow"
        ]
        let adjective = adjectives.randomElement()!
        let noun = nouns.randomElement()!
        let number = Int.random(in: 0...999)
        return "\(adjective)\(noun)\(String(format: "%03d", number))"
    }

    func updateNickname(_ newNickname: String) async throws {
        guard var profile = userProfile else { return }

        // Validate
        guard newNickname.count >= GameConstants.Validation.minNicknameLength,
              newNickname.count <= GameConstants.Validation.maxNicknameLength else {
            throw NSError(domain: "", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Nickname must be 1-20 characters"])
        }

        let regex = try NSRegularExpression(pattern: GameConstants.Validation.nicknamePattern)
        let range = NSRange(newNickname.startIndex..., in: newNickname)
        guard regex.firstMatch(in: newNickname, range: range) != nil else {
            throw NSError(domain: "", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid characters in nickname"])
        }

        // Check cooldown
        if let lastChanged = profile.nicknameChangedAt {
            let cooldownEnd = lastChanged + GameConstants.Validation.nicknameChangeCooldown * 1000
            if Date().timeIntervalSince1970 * 1000 < cooldownEnd {
                throw NSError(domain: "", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "You can only change your nickname once every 30 days"])
            }
        }

        let now = Date().timeIntervalSince1970 * 1000
        profile.nickname = newNickname
        profile.nicknameChangedAt = now
        userProfile = profile

        if !isOfflineMode {
            let docRef = db.collection("users").document(profile.userId)
            try await docRef.updateData([
                "nickname": newNickname,
                "nicknameChangedAt": now
            ])
        }

        saveProfileLocally()
    }

    var userId: String {
        userProfile?.userId ?? ""
    }

    var nickname: String {
        userProfile?.nickname ?? "Unknown"
    }
}

// MARK: - Timeout Helper

func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw NSError(domain: "timeout", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Operation timed out"])
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
