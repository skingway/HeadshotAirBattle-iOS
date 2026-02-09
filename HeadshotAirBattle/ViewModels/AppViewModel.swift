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
    @Published var successMessage: String?

    private let db = Firestore.firestore()

    // MARK: - Computed Properties

    var isSignedInWithApple: Bool {
        userProfile?.authProvider == "apple"
    }

    var authProviderDisplayName: String {
        if isOfflineMode { return "Offline" }
        switch userProfile?.authProvider {
        case "apple": return "Apple"
        default: return "Guest"
        }
    }

    // MARK: - Initialization

    func initialize() async {
        isLoading = true
        defer { isLoading = false }

        // Check if already signed in (e.g., Apple-linked user from previous session)
        if let currentUser = Auth.auth().currentUser {
            print("[AppViewModel] Existing user found: \(currentUser.uid), anonymous=\(currentUser.isAnonymous)")
            await loadOrCreateProfile(userId: currentUser.uid)
            isAuthenticated = true
            return
        }

        // No existing user — sign in anonymously
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

    // MARK: - Apple Sign-In

    func signInWithApple() async {
        errorMessage = nil
        successMessage = nil

        do {
            print("[AppViewModel] Starting Apple Sign-In...")
            let credential = try await AppleSignInService.shared.signIn()
            print("[AppViewModel] Got Apple credential")

            // Save current anonymous user info for potential data migration
            let previousUserId = Auth.auth().currentUser?.uid
            let previousProfile = userProfile
            let wasAnonymous = Auth.auth().currentUser?.isAnonymous ?? true
            print("[AppViewModel] Previous user: \(previousUserId ?? "nil"), anonymous=\(wasAnonymous)")

            // Sign in with Apple credential directly
            // - If Apple ID already linked to a Firebase account → signs into that account
            // - If not linked yet → creates a new Firebase account
            // This avoids the nonce-consumed issue with link() + fallback signIn()
            let authResult = try await Auth.auth().signIn(with: credential)
            let userId = authResult.user.uid
            print("[AppViewModel] Firebase auth complete, userId: \(userId)")

            // Get Apple info stored by delegate
            let appleDisplayName = UserDefaults.standard.string(forKey: "apple_display_name")
            let appleEmail = UserDefaults.standard.string(forKey: "apple_email")
            let now = Date().timeIntervalSince1970 * 1000

            // Build Firestore update data
            var updateData: [String: Any] = [
                "authProvider": "apple",
                "linkedAt": now
            ]
            if let name = appleDisplayName { updateData["appleDisplayName"] = name }
            if let email = appleEmail { updateData["appleEmail"] = email }

            // If UID changed (anonymous → existing Apple account), migrate game data
            if let prevId = previousUserId, prevId != userId, wasAnonymous, let prev = previousProfile {
                print("[AppViewModel] UID changed from \(prevId) to \(userId), migrating data...")
                // Merge stats from anonymous profile into Apple account
                let appleDoc = try? await db.collection("users").document(userId).getDocument()
                let existingGames = appleDoc?.data()?["totalGames"] as? Int ?? 0
                if existingGames == 0 && prev.totalGames > 0 {
                    // Apple account has no games, carry over anonymous stats
                    updateData["nickname"] = prev.nickname
                    updateData["totalGames"] = prev.totalGames
                    updateData["wins"] = prev.wins
                    updateData["losses"] = prev.losses
                    updateData["winRate"] = prev.winRate
                    if let online = prev.onlineGames { updateData["onlineGames"] = online }
                    updateData["createdAt"] = prev.createdAt
                }
                // Clean up old anonymous user data
                try? await db.collection("users").document(prevId).delete()
            }

            try await db.collection("users").document(userId).setData(updateData, merge: true)
            print("[AppViewModel] Firestore updated")

            // Load full profile from Firestore
            await loadOrCreateProfile(userId: userId)
            var profile = userProfile ?? UserProfile(userId: userId, nickname: generateNickname())
            profile.userId = userId
            profile.authProvider = "apple"
            profile.appleDisplayName = appleDisplayName
            profile.appleEmail = appleEmail
            profile.linkedAt = now
            userProfile = profile  // Full assignment triggers @Published
            saveProfileLocally()

            successMessage = "Signed in with Apple"
            print("[AppViewModel] Apple Sign-In complete for user: \(userId), authProvider: \(userProfile?.authProvider ?? "nil")")
        } catch {
            print("[AppViewModel] Apple Sign-In failed: \(error.localizedDescription)")
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try Auth.auth().signOut()
        } catch {
            print("[AppViewModel] Sign out error: \(error.localizedDescription)")
        }

        // Clear Apple-specific data
        UserDefaults.standard.removeObject(forKey: "apple_display_name")
        UserDefaults.standard.removeObject(forKey: "apple_email")
        UserDefaults.standard.removeObject(forKey: "apple_user_id")

        // Re-initialize with new anonymous account
        userProfile = nil
        isAuthenticated = false
        await initialize()
    }

    // MARK: - Delete Account

    func deleteAccount() async {
        guard let userId = userProfile?.userId else { return }

        do {
            // Delete Firestore data
            try await db.collection("users").document(userId).delete()

            // Delete Firebase Auth account
            try await Auth.auth().currentUser?.delete()
        } catch {
            print("[AppViewModel] Delete account error: \(error.localizedDescription)")
        }

        // Clear all local data
        let keys = [
            GameConstants.StorageKeys.offlineUserProfile,
            GameConstants.StorageKeys.offlineStatistics,
            GameConstants.StorageKeys.offlineGameHistory,
            GameConstants.StorageKeys.achievementsData,
            GameConstants.StorageKeys.airplaneSkin,
            GameConstants.StorageKeys.boardTheme,
            GameConstants.StorageKeys.iapPurchases,
            "apple_display_name", "apple_email", "apple_user_id"
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }

        // Re-initialize
        userProfile = nil
        isAuthenticated = false
        await initialize()
    }

    // MARK: - Profile Management

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
                userProfile?.authProvider = data["authProvider"] as? String ?? "anonymous"
                userProfile?.appleDisplayName = data["appleDisplayName"] as? String
                userProfile?.appleEmail = data["appleEmail"] as? String
                userProfile?.linkedAt = data["linkedAt"] as? Double
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
                    "winRate": 0,
                    "authProvider": "anonymous"
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

        // Check cooldown (bypass if nickname_freedom purchased)
        let hasNicknameFreedom = IAPService.shared.isPurchased(.nicknameFreedom)
        if !hasNicknameFreedom, let lastChanged = profile.nicknameChangedAt {
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
