import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Foundation

/// Handles Sign In with Apple authentication flow
class AppleSignInService: NSObject {
    static let shared = AppleSignInService()

    private var currentNonce: String?
    private var continuation: CheckedContinuation<AuthCredential, Error>?

    private override init() {
        super.init()
    }

    /// Initiates Sign In with Apple and returns a Firebase AuthCredential
    func signIn() async throws -> AuthCredential {
        let nonce = randomNonceString()
        currentNonce = nonce

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }

    /// Check if a user's Apple credential is still valid
    func checkCredentialState(userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8),
              let nonce = currentNonce else {
            continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: -1,
                                                    userInfo: [NSLocalizedDescriptionKey: "Failed to get Apple ID credential"]))
            continuation = nil
            return
        }

        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: identityToken,
            rawNonce: nonce
        )

        // Store user info for later use (Apple only sends name/email on first sign-in)
        if let fullName = appleIDCredential.fullName {
            let displayName = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !displayName.isEmpty {
                UserDefaults.standard.set(displayName, forKey: "apple_display_name")
            }
        }
        if let email = appleIDCredential.email {
            UserDefaults.standard.set(email, forKey: "apple_email")
        }
        UserDefaults.standard.set(appleIDCredential.user, forKey: "apple_user_id")

        continuation?.resume(returning: credential)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("[AppleSignIn] Error: \(error.localizedDescription)")
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
