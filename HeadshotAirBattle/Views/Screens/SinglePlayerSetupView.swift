import SwiftUI

struct SinglePlayerSetupView: View {
    @Binding var navigationPath: NavigationPath
    @State private var difficulty = "easy"
    @State private var isAppeared = false

    var body: some View {
        SciFiBgView {
            VStack(spacing: 32) {
                Text("SINGLE PLAYER")
                    .font(AppFonts.orbitron(22, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(3)

                // Difficulty selection
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Select Difficulty")

                        Picker("Difficulty", selection: $difficulty) {
                            Text("Easy").tag("easy")
                            Text("Medium").tag("medium")
                            Text("Hard").tag("hard")
                        }
                        .pickerStyle(.segmented)
                        .colorScheme(.dark)

                        if let aiDiff = GameConstants.AIDifficulty(rawValue: difficulty) {
                            Text(aiDiff.description)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textMuted)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 40)

                // Start button
                PrimaryButton(icon: "\u{26A1}", title: "Start Game") {
                    navigationPath.append(
                        AppRoute.game(difficulty: difficulty, mode: "standard",
                                     boardSize: 10, airplaneCount: 3)
                    )
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.top, 60)
            .opacity(isAppeared ? 1 : 0)
            .offset(y: isAppeared ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    isAppeared = true
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
