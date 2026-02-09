import SwiftUI

struct SkinsView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = SkinsViewModel()
    @State private var showUnlockAlert = false
    @State private var unlockMessage = ""
    @State private var isAppeared = false

    var body: some View {
        SciFiBgView {
            ScrollView {
                VStack(spacing: 24) {
                    // Airplane skins section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Airplane Skins")

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(SkinDefinitions.airplaneSkins, id: \.id) { skin in
                                let totalGames = appViewModel.userProfile?.totalGames ?? 0
                                let wins = appViewModel.userProfile?.wins ?? 0
                                let isUnlocked = viewModel.isSkinUnlocked(skin, totalGames: totalGames, wins: wins)
                                SkinCard(
                                    skin: skin,
                                    isSelected: viewModel.currentSkinId == skin.id,
                                    isUnlocked: isUnlocked,
                                    progressText: viewModel.skinUnlockProgress(skin, totalGames: totalGames, wins: wins)
                                ) {
                                    if isUnlocked {
                                        viewModel.selectSkin(skin.id)
                                    } else {
                                        unlockMessage = viewModel.skinUnlockProgress(skin, totalGames: totalGames, wins: wins)
                                        showUnlockAlert = true
                                    }
                                }
                            }
                        }
                    }

                    // Board themes section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Board Themes")

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
                .opacity(isAppeared ? 1 : 0)
                .offset(y: isAppeared ? 0 : 20)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isAppeared = true
                    }
                }
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
            VStack(spacing: 10) {
                Circle()
                    .fill(Color(hex: skin.color))
                    .frame(width: 60, height: 60)
                    .shadow(color: Color(hex: skin.color).opacity(0.4), radius: 8)
                    .overlay {
                        if !isUnlocked {
                            Circle().fill(.black.opacity(0.4))
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                Text(skin.name)
                    .font(AppFonts.rajdhani(13, weight: .semibold))
                    .foregroundColor(isUnlocked ? .white : AppColors.textMuted)
                    .lineLimit(1)

                if !isUnlocked {
                    Text(progressText)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.warning)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0, green: 30/255, blue: 60/255).opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? AppColors.accent : AppColors.borderLight,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: isSelected ? AppColors.accentGlow.opacity(0.2) : .clear, radius: 10)
            .opacity(isUnlocked ? 1 : 0.6)
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
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: theme.colors.background))
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? AppColors.accent : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? AppColors.accentGlow.opacity(0.2) : .clear, radius: 8)

                Text(theme.name)
                    .font(AppFonts.rajdhani(13, weight: .semibold))
                    .foregroundColor(isUnlocked ? .white : AppColors.textMuted)

                if !isUnlocked {
                    Text(progressText)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.warning)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0, green: 30/255, blue: 60/255).opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? AppColors.accent : AppColors.borderLight,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .opacity(isUnlocked ? 1 : 0.6)
        }
    }
}
