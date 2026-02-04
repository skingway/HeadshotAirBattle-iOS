import SwiftUI

/// Visual turn timer with warning color
struct TurnTimerView: View {
    let timeRemaining: TimeInterval

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption)
            Text(String(format: "%.1f", max(timeRemaining, 0)))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
        }
        .foregroundColor(timerColor)
    }

    private var timerColor: Color {
        if timeRemaining <= GameConstants.TurnTimer.warningThreshold {
            return .red
        }
        return .white
    }
}
