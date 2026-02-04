import SwiftUI

struct AchievementsView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var viewModel = AchievementsViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Progress
                    VStack(spacing: 8) {
                        Text("\(viewModel.unlockedCount)/\(viewModel.totalCount)")
                            .font(.title.bold())
                            .foregroundColor(.cyan)
                        Text("Achievements Unlocked")
                            .font(.caption)
                            .foregroundColor(.gray)
                        ProgressView(value: Double(viewModel.unlockedCount), total: Double(viewModel.totalCount))
                            .tint(.cyan)
                    }
                    .padding()

                    // Categories
                    ForEach(AchievementDefinitions.Category.allCases, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.displayName)
                                .font(.headline)
                                .foregroundColor(.cyan)

                            ForEach(viewModel.achievements(for: category), id: \.id) { achievement in
                                AchievementRow(
                                    achievement: achievement,
                                    isUnlocked: viewModel.isUnlocked(achievement.id)
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
        .onAppear { viewModel.load() }
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
                    .font(.subheadline.bold())
                    .foregroundColor(isUnlocked ? .white : .gray)
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(isUnlocked ? 0.15 : 0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    Color(hex: AchievementDefinitions.rarityColor(achievement.rarity)).opacity(isUnlocked ? 0.5 : 0.1),
                    lineWidth: 1
                )
        )
    }
}
