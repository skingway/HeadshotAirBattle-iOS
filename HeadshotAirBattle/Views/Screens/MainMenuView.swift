import SwiftUI

struct MainMenuView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("HEADSHOT")
                        .font(.system(size: 42, weight: .black))
                        .foregroundColor(.white)
                    Text("AIR BATTLE")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.cyan)
                }

                Spacer()

                // Menu buttons
                VStack(spacing: 16) {
                    MenuButton(title: "Single Player", icon: "airplane") {
                        navigationPath.append(AppRoute.singlePlayerSetup)
                    }

                    MenuButton(title: "Online PvP", icon: "wifi") {
                        navigationPath.append(AppRoute.onlineMode)
                    }

                    MenuButton(title: "Custom Mode", icon: "slider.horizontal.3") {
                        navigationPath.append(AppRoute.customMode)
                    }

                    HStack(spacing: 16) {
                        SmallMenuButton(title: "Profile", icon: "person.fill") {
                            navigationPath.append(AppRoute.profile)
                        }
                        SmallMenuButton(title: "Leaderboard", icon: "trophy.fill") {
                            navigationPath.append(AppRoute.leaderboard)
                        }
                    }

                    HStack(spacing: 16) {
                        SmallMenuButton(title: "History", icon: "clock.fill") {
                            navigationPath.append(AppRoute.gameHistory)
                        }
                        SmallMenuButton(title: "Achievements", icon: "star.fill") {
                            navigationPath.append(AppRoute.achievements)
                        }
                    }

                    HStack(spacing: 16) {
                        SmallMenuButton(title: "Skins", icon: "paintbrush.fill") {
                            navigationPath.append(AppRoute.skins)
                        }
                        SmallMenuButton(title: "Store", icon: "cart.fill") {
                            navigationPath.append(AppRoute.store)
                        }
                    }

                    SmallMenuButton(title: "Settings", icon: "gearshape.fill") {
                        navigationPath.append(AppRoute.settings)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Welcome text
                if appViewModel.isAuthenticated {
                    Text("Welcome, \(appViewModel.nickname)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Banner ad at bottom
                ConditionalBannerAd()
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
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                    )
            )
        }
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
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}
