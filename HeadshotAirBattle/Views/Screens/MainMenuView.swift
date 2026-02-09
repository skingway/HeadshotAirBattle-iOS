import SwiftUI

struct MainMenuView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var floatOffset: CGFloat = 0
    @State private var isAppeared = false

    var body: some View {
        SciFiBgView {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // Logo
                VStack(spacing: 8) {
                    Text("HEADSHOT")
                        .font(AppFonts.orbitron(26, weight: .black))
                        .foregroundColor(.white)

                    Text("AIR BATTLE")
                        .font(AppFonts.orbitron(10, weight: .regular))
                        .foregroundColor(AppColors.accent.opacity(0.6))
                        .tracking(6)
                }

                // Floating plane icon
                Text("\u{2708}\u{FE0F}")
                    .font(.system(size: 80))
                    .shadow(color: AppColors.accentGlow, radius: 20)
                    .offset(y: floatOffset)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            floatOffset = -8
                        }
                    }
                    .padding(.vertical, 30)

                // Menu buttons
                VStack(spacing: 12) {
                    PrimaryButton(icon: "\u{26A1}", title: "Single Player") {
                        navigationPath.append(AppRoute.singlePlayerSetup)
                    }

                    SecondaryButton(icon: "\u{1F310}", title: "Online PvP") {
                        navigationPath.append(AppRoute.onlineMode)
                    }

                    TertiaryButton(icon: "\u{1F3AE}", title: "Custom Mode") {
                        navigationPath.append(AppRoute.customMode)
                    }

                    HStack(spacing: 12) {
                        SciFiSmallMenuButton(title: "Profile", icon: "person.fill") {
                            navigationPath.append(AppRoute.profile)
                        }
                        SciFiSmallMenuButton(title: "Leaderboard", icon: "trophy.fill") {
                            navigationPath.append(AppRoute.leaderboard)
                        }
                    }

                    HStack(spacing: 12) {
                        SciFiSmallMenuButton(title: "History", icon: "clock.fill") {
                            navigationPath.append(AppRoute.gameHistory)
                        }
                        SciFiSmallMenuButton(title: "Achievements", icon: "star.fill") {
                            navigationPath.append(AppRoute.achievements)
                        }
                    }

                    HStack(spacing: 12) {
                        SciFiSmallMenuButton(title: "Skins", icon: "paintbrush.fill") {
                            navigationPath.append(AppRoute.skins)
                        }
                        SciFiSmallMenuButton(title: "Store", icon: "cart.fill") {
                            navigationPath.append(AppRoute.store)
                        }
                    }

                    SciFiSmallMenuButton(title: "Settings", icon: "gearshape.fill") {
                        navigationPath.append(AppRoute.settings)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Welcome text
                if appViewModel.isAuthenticated {
                    Text("Welcome, \(appViewModel.nickname)")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textMuted)
                }

                // Banner ad at bottom
                ConditionalBannerAd()
            }
            .opacity(isAppeared ? 1 : 0)
            .offset(y: isAppeared ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    isAppeared = true
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Menu Button Components

struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title.uppercased())
                    .font(AppFonts.buttonText)
                    .tracking(2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.primaryGradient)
            )
            .shadow(color: AppColors.accentGlow.opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SmallMenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppColors.accent)
                Text(title.uppercased())
                    .font(AppFonts.orbitron(9, weight: .semibold))
                    .tracking(1)
            }
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SciFiSmallMenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppColors.accent)
                Text(title.uppercased())
                    .font(AppFonts.orbitron(9, weight: .semibold))
                    .tracking(1)
            }
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
