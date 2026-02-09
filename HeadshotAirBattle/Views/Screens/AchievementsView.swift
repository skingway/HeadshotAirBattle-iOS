import SwiftUI

struct AchievementsView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var viewModel = AchievementsViewModel()
    @State private var isAppeared = false

    var body: some View {
        SciFiBgView {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress
                    VStack(spacing: 8) {
                        Text("\(viewModel.unlockedCount)/\(viewModel.totalCount)")
                            .font(AppFonts.bigNumber)
                            .foregroundColor(AppColors.accent)
                        Text("ACHIEVEMENTS UNLOCKED")
                            .font(AppFonts.orbitron(10, weight: .semibold))
                            .foregroundColor(AppColors.textMuted)
                            .tracking(2)
                        ProgressView(value: Double(viewModel.unlockedCount), total: Double(viewModel.totalCount))
                            .tint(AppColors.accent)
                    }
                    .padding()

                    // Categories
                    ForEach(AchievementDefinitions.Category.allCases, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: category.displayName)

                            ForEach(Array(viewModel.achievements(for: category).enumerated()), id: \.element.id) { index, achievement in
                                AchievementRow(
                                    achievement: achievement,
                                    isUnlocked: viewModel.isUnlocked(achievement.id)
                                )
                                .opacity(isAppeared ? 1 : 0)
                                .offset(x: isAppeared ? 0 : 30)
                                .animation(
                                    .easeOut(duration: 0.25).delay(Double(index) * 0.06),
                                    value: isAppeared
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load()
            withAnimation(.easeOut(duration: 0.3)) {
                isAppeared = true
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: AchievementDef
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(achievement.icon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(AppFonts.rajdhani(15, weight: .semibold))
                    .foregroundColor(isUnlocked ? .white : AppColors.textMuted)
                Text(achievement.description)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textMuted)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.success)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(AppColors.textMuted)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0, green: 30/255, blue: 60/255).opacity(isUnlocked ? 0.4 : 0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    Color(hex: AchievementDefinitions.rarityColor(achievement.rarity)).opacity(isUnlocked ? 0.5 : 0.1),
                    lineWidth: 1
                )
        )
    }
}
