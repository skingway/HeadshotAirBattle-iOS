import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Manages anonymous authentication and user profile
class AuthService {
    static let shared = AuthService()

    private let db = Firestore.firestore()
    private(set) var currentUser: User?
    private(set) var userProfile: UserProfile?
    private(set) var isOfflineMode = false

    private init() {}

    /// Initialize authentication with fallback to offline mode
    func initialize() async -> UserProfile? {
        do {
            let result = try await withTimeout(seconds: 5) {
                try await Auth.auth().signInAnonymously()
            }
            currentUser = result.user
            let profile = await loadOrCreateProfile(userId: result.user.uid)
            userProfile = profile
            isOfflineMode = false
            return profile
        } catch {
            print("[AuthService] Auth failed: \(error.localizedDescription)")
            isOfflineMode = true
            return loadOfflineProfile()
        }
    }

    private func loadOrCreateProfile(userId: String) async -> UserProfile {
        let docRef = db.collection("users").document(userId)

        do {
            let document = try await docRef.getDocument()
            if document.exists, let data = document.data() {
                var profile = UserProfile(
                    userId: userId,
                    nickname: data["nickname"] as? String ?? generateNickname()
                )
                profile.totalGames = data["totalGames"] as? Int ?? 0
                profile.wins = data["wins"] as? Int ?? 0
                profile.losses = data["losses"] as? Int ?? 0
                profile.winRate = data["winRate"] as? Double ?? 0
                profile.onlineGames = data["onlineGames"] as? Int
                profile.createdAt = data["createdAt"] as? Double ?? Date().timeIntervalSince1970 * 1000
                profile.nicknameChangedAt = data["nicknameChangedAt"] as? Double
                profile.selectedBackground = data["selectedBackground"] as? String
                saveProfileLocally(profile)
                return profile
            } else {
                let profile = createNewProfile(userId: userId)
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
                saveProfileLocally(profile)
                return profile
            }
        } catch {
            print("[AuthService] Firestore error: \(error.localizedDescription)")
            return loadOfflineProfile() ?? createNewProfile(userId: userId)
        }
    }

    private func createNewProfile(userId: String) -> UserProfile {
        let profile = UserProfile(userId: userId, nickname: generateNickname())
        saveProfileLocally(profile)
        return profile
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

    private func saveProfileLocally(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: GameConstants.StorageKeys.offlineUserProfile)
        }
    }

    private func loadOfflineProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: GameConstants.StorageKeys.offlineUserProfile),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        userProfile = profile
        return profile
    }

    func getUserId() -> String? {
        return currentUser?.uid ?? userProfile?.userId
    }

    func getNickname() -> String {
        return userProfile?.nickname ?? "Unknown"
    }

    func signOut() {
        try? Auth.auth().signOut()
        currentUser = nil
        userProfile = nil
    }
}
