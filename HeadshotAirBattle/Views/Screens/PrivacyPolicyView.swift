import SwiftUI

struct PrivacyPolicyView: View {
    @Binding var navigationPath: NavigationPath

    var body: some View {
        SciFiBgView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Privacy Policy")
                            .font(AppFonts.orbitron(22, weight: .bold))
                            .foregroundColor(.white)

                        Text("Last Updated: February 7, 2026")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textMuted)
                    }

                    sectionView(title: "Introduction",
                        content: "This privacy policy explains how HeadshotAirBattle collects, uses, and protects your information when you use our mobile application.")

                    sectionView(title: "Information We Collect", content: """
                        1. User Account Information
                        \u{2022} Anonymous User ID: Generated automatically by Firebase Authentication
                        \u{2022} Apple ID Information: If you sign in with Apple, we receive your name and email (if shared)
                        \u{2022} Nickname: Optional username you choose (can be changed once every 30 days)
                        \u{2022} User Statistics: Win/loss records, total games played, achievements earned

                        2. Game Data
                        \u{2022} Match History: Records of your completed games (AI and online)
                        \u{2022} Game Settings: Your preferences for skins, themes, and gameplay options
                        \u{2022} Battle Statistics: Hit accuracy, kills, and other in-game performance metrics
                        \u{2022} Purchase History: Records of in-app purchases

                        3. Multiplayer Data
                        \u{2022} Online Game Sessions: When you play online, we store game state in real-time for matchmaking and gameplay
                        \u{2022} Leaderboard Data: Your ranking, win rate, and total wins (publicly visible)

                        4. Advertising Data
                        \u{2022} Advertising Identifier: Used by Google AdMob to serve ads (with your consent)
                        \u{2022} Ad interaction data: Ad impressions and clicks
                        """)

                    sectionView(title: "How We Use Your Information", content: """
                        \u{2022} Provide Game Services: Enable single-player and multiplayer gameplay
                        \u{2022} Match Players: Connect you with opponents in online matches
                        \u{2022} Track Progress: Save your achievements, unlocked content, and statistics
                        \u{2022} Serve Ads: Display relevant advertisements (can be removed via in-app purchase)
                        \u{2022} Process Purchases: Handle in-app purchase transactions
                        \u{2022} Display Leaderboards: Show global rankings and competitive standings
                        """)

                    sectionView(title: "Third-Party Services", content: """
                        Our app uses the following third-party services:

                        Firebase (Google)
                        \u{2022} Purpose: Authentication, real-time database, cloud storage
                        \u{2022} Privacy Policy: firebase.google.com/support/privacy

                        Google AdMob
                        \u{2022} Purpose: Display advertisements
                        \u{2022} Privacy Policy: policies.google.com/privacy

                        Apple (Sign In with Apple / StoreKit)
                        \u{2022} Purpose: User authentication, in-app purchases
                        \u{2022} Privacy Policy: apple.com/privacy
                        """)

                    sectionView(title: "Data Storage and Security", content: """
                        \u{2022} All data is stored securely using Firebase (Google Cloud Platform)
                        \u{2022} Data is encrypted in transit using industry-standard TLS/SSL protocols
                        \u{2022} We do not sell or share your data with third parties for marketing purposes
                        """)

                    sectionView(title: "Your Rights", content: """
                        \u{2022} Access: View your stored data within the app (Profile, History, Achievements)
                        \u{2022} Update: Change your nickname (once per 30 days, or unlimited with Nickname Freedom purchase)
                        \u{2022} Delete: Delete your account and all associated data from Settings
                        \u{2022} Opt-out: Control ad tracking via iOS Settings > Privacy > Tracking
                        """)

                    sectionView(title: "GDPR Compliance (EU Users)", content: """
                        If you are in the European Union, you have additional rights including:
                        \u{2022} Right to access, correct, or erase your personal data
                        \u{2022} Right to data portability
                        \u{2022} Right to restrict or object to processing
                        \u{2022} Right to withdraw consent at any time
                        """)

                    sectionView(title: "CCPA Compliance (California)", content: """
                        If you are a California resident, you have the right to:
                        \u{2022} Know what personal information is collected
                        \u{2022} Request deletion of your personal information
                        \u{2022} Opt-out of the sale of personal information (we do not sell data)
                        """)

                    sectionView(title: "Children's Privacy",
                        content: "Our app is rated 4+ and does not knowingly collect personal information from children. No registration with personal details is required.")

                    sectionView(title: "Data Retention", content: """
                        \u{2022} Active Users: Data is retained as long as your account is active
                        \u{2022} Inactive Users: Anonymous accounts may be purged after 180 days of inactivity
                        \u{2022} Account Deletion: Data deleted within 30 days of request
                        \u{2022} Purchase Records: Retained for legal compliance
                        """)

                    sectionView(title: "Contact Us", content: """
                        If you have questions about this privacy policy:
                        \u{2022} GitHub: github.com/skingway/HeadshotAirBattle-iOS/issues
                        """)

                    Text("By using HeadshotAirBattle, you consent to this privacy policy and agree to its terms.")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textMuted)
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
                .font(AppFonts.sectionTitle)
                .foregroundColor(AppColors.accent)
            Text(content)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
