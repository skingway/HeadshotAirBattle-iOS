import SwiftUI

struct SkinsView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = SkinsViewModel()
    @State private var showUnlockAlert = false
    @State private var unlockMessage = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Airplane skins section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Airplane Skins")
                            .font(.headline)
                            .foregroundColor(.cyan)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(SkinDefinitions.airplaneSkins, id: \.id) { skin in
                                let totalGames = appViewModel.userProfile?.totalGames ?? 0
                                let isUnlocked = viewModel.isSkinUnlocked(skin, totalGames: totalGames)
                                SkinCard(
                                    skin: skin,
                                    isSelected: viewModel.currentSkinId == skin.id,
                                    isUnlocked: isUnlocked,
                                    progressText: viewModel.skinUnlockProgress(skin, totalGames: totalGames)
                                ) {
                                    if isUnlocked {
                                        viewModel.selectSkin(skin.id)
                                    } else {
                                        unlockMessage = viewModel.skinUnlockProgress(skin, totalGames: totalGames)
                                        showUnlockAlert = true
                                    }
                                }
                            }
                        }
                    }

                    // Board themes section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Board Themes")
                            .font(.headline)
                            .foregroundColor(.cyan)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(SkinDefinitions.boardThemes, id: \.id) { theme in
                                let totalWins = appViewModel.userProfile?.wins ?? 0
                                let isUnlocked = viewModel.isThemeUnlocked(theme, totalWins: totalWins)
                                ThemeCard(
                                    theme: theme,
                                    isSelected: viewModel.currentThemeId == theme.id,
                                    isUnlocked: isUnlocked,
                                    progressText: viewModel.themeUnlockProgress(theme, totalWins: totalWins)
                                ) {
                                    if isUnlocked {
                                        viewModel.selectTheme(theme.id)
                                    } else {
                                        unlockMessage = viewModel.themeUnlockProgress(theme, totalWins: totalWins)
                                        showUnlockAlert = true
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Skins & Themes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
        .alert("Locked", isPresented: $showUnlockAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(unlockMessage)
        }
    }
}

struct SkinCard: View {
    let skin: AirplaneSkinDef
    let isSelected: Bool
    let isUnlocked: Bool
    let progressText: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: skin.color))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle().stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 2)
                    )

                Text(skin.name)
                    .font(.caption2)
                    .foregroundColor(isUnlocked ? .white : .gray)
                    .lineLimit(1)

                if !isUnlocked {
                    Text(progressText)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .lineLimit(1)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(isSelected ? 0.3 : 0.1))
            .cornerRadius(8)
            .opacity(isUnlocked ? 1 : 0.5)
        }
    }
}

struct ThemeCard: View {
    let theme: BoardThemeDef
    let isSelected: Bool
    let isUnlocked: Bool
    let progressText: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: theme.colors.background))
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 2)
                    )

                Text(theme.name)
                    .font(.caption)
                    .foregroundColor(isUnlocked ? .white : .gray)

                if !isUnlocked {
                    Text(progressText)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(isSelected ? 0.3 : 0.1))
            .cornerRadius(8)
            .opacity(isUnlocked ? 1 : 0.5)
        }
    }
}
