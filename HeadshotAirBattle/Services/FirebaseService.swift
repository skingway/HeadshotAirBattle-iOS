import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase

/// Firebase service singleton for centralized access
class FirebaseService {
    static let shared = FirebaseService()

    private(set) var isInitialized = false
    private(set) var isOfflineMode = false

    private init() {}

    func initialize() async {
        // FirebaseApp.configure() is called in AppDelegate
        // Test connectivity
        do {
            _ = try await withTimeout(seconds: 5) {
                try await Auth.auth().signInAnonymously()
            }
            isInitialized = true
            isOfflineMode = false
        } catch {
            print("[FirebaseService] Initialization failed: \(error.localizedDescription)")
            isInitialized = true
            isOfflineMode = true
        }
    }

    var auth: Auth {
        Auth.auth()
    }

    var firestore: Firestore {
        Firestore.firestore()
    }

    var database: Database {
        Database.database(url: "https://airplane-battle-7a3fd-default-rtdb.firebaseio.com")
    }
}
