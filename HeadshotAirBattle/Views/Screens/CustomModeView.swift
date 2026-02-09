import SwiftUI

struct CustomModeView: View {
    @Binding var navigationPath: NavigationPath
    @State private var boardSize: Double = 15
    @State private var airplaneCount: Double = 3
    @State private var difficulty = "easy"
    @State private var validationMessage: String?
    @State private var isAppeared = false

    var body: some View {
        SciFiBgView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("CUSTOM MODE")
                        .font(AppFonts.orbitron(22, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(3)

                    // Board size
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Board Size: \(Int(boardSize))\u{00D7}\(Int(boardSize))")
                                .font(AppFonts.rajdhani(16, weight: .semibold))
                                .foregroundColor(.white)
                            Slider(value: $boardSize, in: 10...20, step: 1)
                                .tint(AppColors.accent)
                        }
                    }

                    // Airplane count
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Airplanes: \(Int(airplaneCount))")
                                .font(AppFonts.rajdhani(16, weight: .semibold))
                                .foregroundColor(.white)
                            Slider(value: $airplaneCount, in: 1...10, step: 1)
                                .tint(AppColors.accent)
                        }
                    }

                    // Difficulty
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Difficulty")
                            Picker("Difficulty", selection: $difficulty) {
                                Text("Easy").tag("easy")
                                Text("Medium").tag("medium")
                                Text("Hard").tag("hard")
                            }
                            .pickerStyle(.segmented)
                            .colorScheme(.dark)
                        }
                    }

                    // Validation
                    if let message = validationMessage {
                        Text(message)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.warning)
                            .multilineTextAlignment(.center)
                    }

                    // Start button
                    PrimaryButton(icon: "\u{26A1}", title: "Start Game") {
                        startGame()
                    }
                    .disabled(validationMessage != nil)
                    .opacity(validationMessage != nil ? 0.5 : 1)
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
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: boardSize) { _ in validate() }
        .onChange(of: airplaneCount) { _ in validate() }
    }

    private func validate() {
        let result = GameConstants.validateAirplaneCountForBoardSize(
            airplaneCount: Int(airplaneCount),
            boardSize: Int(boardSize)
        )
        validationMessage = result.valid ? nil : result.reason
    }

    private func startGame() {
        navigationPath.append(
            AppRoute.game(
                difficulty: difficulty,
                mode: "custom",
                boardSize: Int(boardSize),
                airplaneCount: Int(airplaneCount)
            )
        )
    }
}
