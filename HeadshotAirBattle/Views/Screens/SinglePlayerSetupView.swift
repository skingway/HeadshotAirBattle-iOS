import SwiftUI

struct SinglePlayerSetupView: View {
    @Binding var navigationPath: NavigationPath
    @State private var difficulty = "easy"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Text("Single Player")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                // 难度选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Difficulty")
                        .font(.headline)
                        .foregroundColor(.white)

                    Picker("Difficulty", selection: $difficulty) {
                        Text("Easy").tag("easy")
                        Text("Medium").tag("medium")
                        Text("Hard").tag("hard")
                    }
                    .pickerStyle(.segmented)
                    .colorScheme(.dark)

                    // 难度描述
                    if let aiDiff = GameConstants.AIDifficulty(rawValue: difficulty) {
                        Text(aiDiff.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 40)

                // 开始按钮
                Button(action: {
                    navigationPath.append(
                        AppRoute.game(difficulty: difficulty, mode: "standard",
                                     boardSize: 10, airplaneCount: 3)
                    )
                }) {
                    Text("Start Game")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cyan)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.top, 60)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
