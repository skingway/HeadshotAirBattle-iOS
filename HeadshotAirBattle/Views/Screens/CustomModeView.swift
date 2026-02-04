import SwiftUI

struct CustomModeView: View {
    @Binding var navigationPath: NavigationPath
    @State private var boardSize: Double = 15
    @State private var airplaneCount: Double = 3
    @State private var difficulty = "easy"
    @State private var validationMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Custom Mode")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    // Board size
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Board Size: \(Int(boardSize))x\(Int(boardSize))")
                            .foregroundColor(.white)
                        Slider(value: $boardSize, in: 10...20, step: 1)
                            .tint(.cyan)
                    }

                    // Airplane count
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Airplanes: \(Int(airplaneCount))")
                            .foregroundColor(.white)
                        Slider(value: $airplaneCount, in: 1...10, step: 1)
                            .tint(.cyan)
                    }

                    // Difficulty
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Difficulty")
                            .foregroundColor(.white)
                        Picker("Difficulty", selection: $difficulty) {
                            Text("Easy").tag("easy")
                            Text("Medium").tag("medium")
                            Text("Hard").tag("hard")
                        }
                        .pickerStyle(.segmented)
                    }

                    // Validation
                    if let message = validationMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }

                    // Start button
                    Button(action: startGame) {
                        Text("Start Game")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(validationMessage != nil)
                }
                .padding()
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
