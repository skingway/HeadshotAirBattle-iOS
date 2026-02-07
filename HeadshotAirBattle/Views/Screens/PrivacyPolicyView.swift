import SwiftUI

struct PrivacyPolicyView: View {
    @Binding var navigationPath: NavigationPath

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Privacy Policy")
                            .font(.title.bold())
                            .foregroundColor(.white)

                        Text("Last Updated: February 7, 2026")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    sectionView(title: "Introduction",
                        content: "This privacy policy explains how HeadshotAirBattle collects, uses, and protects your information when you use our mobile application.")

                    sectionView(title: "Information We Collect", content: """
                        1. User Account Information
                        • Anonymous User ID: Generated automatically by Firebase Authentication
                        • Apple ID Information: If you sign in with Apple, we receive your name and email (if shared)
                        • Nickname: Optional username you choose (can be changed once every 30 days)
                        • User Statistics: Win/loss records, total games played, achievements earned

                        2. Game Data
                        • Match History: Records of your completed games (AI and online)
                        • Game Settings: Your preferences for skins, themes, and gameplay options
                        • Battle Statistics: Hit accuracy, kills, and other in-game performance metrics
                        • Purchase History: Records of in-app purchases

                        3. Multiplayer Data
                        • Online Game Sessions: When you play online, we store game state in real-time for matchmaking and gameplay
                        • Leaderboard Data: Your ranking, win rate, and total wins (publicly visible)

                        4. Advertising Data
                        • Advertising Identifier: Used by Google AdMob to serve ads (with your consent)
                        • Ad interaction data: Ad impressions and clicks
                        """)

                    sectionView(title: "How We Use Your Information", content: """
                        • Provide Game Services: Enable single-player and multiplayer gameplay
                        • Match Players: Connect you with opponents in online matches
                        • Track Progress: Save your achievements, unlocked content, and statistics
                        • Serve Ads: Display relevant advertisements (can be removed via in-app purchase)
                        • Process Purchases: Handle in-app purchase transactions
                        • Display Leaderboards: Show global rankings and competitive standings
                        """)

                    sectionView(title: "Third-Party Services", content: """
                        Our app uses the following third-party services:

                        Firebase (Google)
                        • Purpose: Authentication, real-time database, cloud storage
                        • Privacy Policy: firebase.google.com/support/privacy

                        Google AdMob
                        • Purpose: Display advertisements
                        • Privacy Policy: policies.google.com/privacy

                        Apple (Sign In with Apple / StoreKit)
                        • Purpose: User authentication, in-app purchases
                        • Privacy Policy: apple.com/privacy
                        """)

                    sectionView(title: "Data Storage and Security", content: """
                        • All data is stored securely using Firebase (Google Cloud Platform)
                        • Data is encrypted in transit using industry-standard TLS/SSL protocols
                        • We do not sell or share your data with third parties for marketing purposes
                        """)

                    sectionView(title: "Your Rights", content: """
                        • Access: View your stored data within the app (Profile, History, Achievements)
                        • Update: Change your nickname (once per 30 days, or unlimited with Nickname Freedom purchase)
                        • Delete: Delete your account and all associated data from Settings
                        • Opt-out: Control ad tracking via iOS Settings > Privacy > Tracking
                        """)

                    sectionView(title: "GDPR Compliance (EU Users)", content: """
                        If you are in the European Union, you have additional rights including:
                        • Right to access, correct, or erase your personal data
                        • Right to data portability
                        • Right to restrict or object to processing
                        • Right to withdraw consent at any time
                        """)

                    sectionView(title: "CCPA Compliance (California)", content: """
                        If you are a California resident, you have the right to:
                        • Know what personal information is collected
                        • Request deletion of your personal information
                        • Opt-out of the sale of personal information (we do not sell data)
                        """)

                    sectionView(title: "Children's Privacy",
                        content: "Our app is rated 4+ and does not knowingly collect personal information from children. No registration with personal details is required.")

                    sectionView(title: "Data Retention", content: """
                        • Active Users: Data is retained as long as your account is active
                        • Inactive Users: Anonymous accounts may be purged after 180 days of inactivity
                        • Account Deletion: Data deleted within 30 days of request
                        • Purchase Records: Retained for legal compliance
                        """)

                    sectionView(title: "Contact Us", content: """
                        If you have questions about this privacy policy:
                        • GitHub: github.com/skingway/HeadshotAirBattle-iOS/issues
                        """)

                    Text("By using HeadshotAirBattle, you consent to this privacy policy and agree to its terms.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                }
                .padding()
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionView(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.cyan)
            Text(content)
                .font(.body)
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
