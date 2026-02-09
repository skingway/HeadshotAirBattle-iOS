import SwiftUI

struct BattleReportView: View {
    @Binding var navigationPath: NavigationPath
    let gameData: GameHistoryEntry
    private let themeColors = SkinDefinitions.currentThemeColors()
    @State private var trophyFloat: CGFloat = 0
    @State private var isAppeared = false

    private var isVictory: Bool {
        gameData.winner == gameData.userId
    }

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = (screenWidth - 80) / 2
        return min(max(availableWidth / CGFloat(gameData.boardSize), 12), 20)
    }

    private var estimatedDuration: String {
        let seconds: Int
        if let startedAt = gameData.startedAt, startedAt > 0 {
            // Use real timestamps for accurate duration
            seconds = Int((gameData.completedAt - startedAt) / 1000)
        } else {
            // Fallback: estimate 5 seconds per turn
            seconds = gameData.totalTurns * 5
        }
        let clampedSeconds = max(seconds, 0)
        let minutes = clampedSeconds / 60
        let remainingSeconds = clampedSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        }
        return "\(clampedSeconds)s"
    }

    private var playerEfficiency: String {
        guard let stats = gameData.playerStats else { return "N/A" }
        let total = stats.hits + stats.misses
        guard total > 0 else { return "0%" }
        let efficiency = Double(stats.hits) / Double(total) * 100
        return String(format: "%.1f%%", efficiency)
    }

    var body: some View {
        SciFiBgView {
            ScrollView {
                VStack(spacing: 0) {
                    // Victory/Defeat banner
                    VStack(spacing: 8) {
                        Text(isVictory ? "\u{1F3C6}" : "\u{1F480}")
                            .font(.system(size: 48))
                            .shadow(color: isVictory
                                ? AppColors.gold.opacity(0.5)
                                : AppColors.danger.opacity(0.5),
                                radius: 15)
                            .offset(y: trophyFloat)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                    trophyFloat = -8
                                }
                            }

                        Text(isVictory ? "VICTORY" : "DEFEAT")
                            .font(AppFonts.orbitron(32, weight: .black))
                            .foregroundColor(isVictory ? AppColors.gold : AppColors.danger)
                            .tracking(4)
                    }
                    .padding(.vertical, 20)

                    // Info tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            InfoTag(text: "\u{229E} \(gameData.boardSize)\u{00D7}\(gameData.boardSize)")
                            InfoTag(text: "\u{2708} \(gameData.airplaneCount) Ships")
                            InfoTag(text: "\u{27F3} \(gameData.totalTurns) Turns")
                            InfoTag(text: "\u{23F1} ~\(estimatedDuration)")
                            InfoTag(text: "\u{25CE} \(playerEfficiency) Hit Rate")
                        }
                        .padding(.horizontal, 16)
                    }

                    // Score cards
                    HStack(spacing: 12) {
                        // Winner card
                        CardHighlightView {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Text("\u{1F451}")
                                    Text("You")
                                        .font(AppFonts.orbitron(13, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                if let stats = gameData.playerStats {
                                    HStack(spacing: 20) {
                                        VStack {
                                            Text("\(stats.hits)")
                                                .font(AppFonts.bigNumber)
                                                .foregroundColor(AppColors.accent)
                                            Text("HITS")
                                                .font(AppFonts.caption)
                                                .foregroundColor(AppColors.textMuted)
                                                .tracking(1)
                                        }
                                        VStack {
                                            Text("\(stats.kills)")
                                                .font(AppFonts.bigNumber)
                                                .foregroundColor(AppColors.accent)
                                            Text("KILLS")
                                                .font(AppFonts.caption)
                                                .foregroundColor(AppColors.textMuted)
                                                .tracking(1)
                                        }
                                    }
                                }
                            }
                        }

                        // Opponent card
                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(gameData.opponent)
                                    .font(AppFonts.orbitron(13, weight: .semibold))
                                    .foregroundColor(.white)
                                if let stats = gameData.aiStats {
                                    HStack(spacing: 20) {
                                        VStack {
                                            Text("\(stats.hits)")
                                                .font(AppFonts.bigNumber)
                                                .foregroundColor(AppColors.danger)
                                            Text("HITS")
                                                .font(AppFonts.caption)
                                                .foregroundColor(AppColors.textMuted)
                                                .tracking(1)
                                        }
                                        VStack {
                                            Text("\(stats.kills)")
                                                .font(AppFonts.bigNumber)
                                                .foregroundColor(AppColors.danger)
                                            Text("KILLS")
                                                .font(AppFonts.caption)
                                                .foregroundColor(AppColors.textMuted)
                                                .tracking(1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    // Battle Boards
                    if gameData.playerBoardData != nil || gameData.aiBoardData != nil {
                        SectionHeader(title: "Battle Map")
                            .padding(.horizontal, 16)

                        CardView {
                            HStack(alignment: .top, spacing: 16) {
                                VStack(spacing: 4) {
                                    Text("YOUR FLEET")
                                        .font(AppFonts.orbitron(10, weight: .semibold))
                                        .foregroundColor(AppColors.success)
                                    if let boardData = gameData.playerBoardData {
                                        ReportBoardView(
                                            boardData: boardData,
                                            cellSize: cellSize,
                                            themeColors: themeColors,
                                            isPlayerBoard: true
                                        )
                                    }
                                }

                                VStack(spacing: 4) {
                                    Text("ENEMY FLEET")
                                        .font(AppFonts.orbitron(10, weight: .semibold))
                                        .foregroundColor(AppColors.accent)
                                    if let boardData = gameData.aiBoardData {
                                        ReportBoardView(
                                            boardData: boardData,
                                            cellSize: cellSize,
                                            themeColors: themeColors,
                                            isPlayerBoard: false
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Stats comparison
                    HStack(alignment: .top, spacing: 12) {
                        if let stats = gameData.playerStats {
                            VStack(spacing: 0) {
                                SectionHeader(title: "Your Stats", color: AppColors.accent)
                                CardView {
                                    VStack(spacing: 0) {
                                        StatRow(label: "Hits", value: "\(stats.hits)")
                                        DividerLine()
                                        StatRow(label: "Misses", value: "\(stats.misses)")
                                        DividerLine()
                                        StatRow(label: "Kills", value: "\(stats.kills)")
                                        let total = stats.hits + stats.misses
                                        if total > 0 {
                                            DividerLine()
                                            StatRow(label: "Accuracy", value: String(format: "%.0f%%", Double(stats.hits) / Double(total) * 100), highlight: true)
                                        }
                                    }
                                }
                            }
                        }

                        if let aiStats = gameData.aiStats {
                            VStack(spacing: 0) {
                                SectionHeader(title: "Opponent", color: AppColors.warning)
                                CardView {
                                    VStack(spacing: 0) {
                                        StatRow(label: "Hits", value: "\(aiStats.hits)")
                                        DividerLine()
                                        StatRow(label: "Misses", value: "\(aiStats.misses)")
                                        DividerLine()
                                        StatRow(label: "Kills", value: "\(aiStats.kills)")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Match details
                    SectionHeader(title: "Match Details")
                        .padding(.horizontal, 16)
                    CardView {
                        VStack(spacing: 0) {
                            StatRow(label: "Opponent", value: gameData.opponent)
                            DividerLine()
                            StatRow(label: "Type", value: gameData.gameType == "ai" ? "vs AI" : "Online")
                            DividerLine()
                            StatRow(label: "Date", value: formatDate(gameData.completedAt))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
                .opacity(isAppeared ? 1 : 0)
                .offset(y: isAppeared ? 0 : 20)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isAppeared = true
                    }
                }
            }
        }
        .navigationTitle("Battle Report")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AchievementService.shared.manuallyUnlock("analyst")
        }
    }

    private func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Battle report board view
struct ReportBoardView: View {
    let boardData: BoardData
    let cellSize: CGFloat
    let themeColors: ThemeColors
    let isPlayerBoard: Bool

    var body: some View {
        let airplanes = boardData.airplanes.map { Airplane.fromData($0) }
        let attackedCells = Set(boardData.attackedCells)

        VStack(spacing: 0) {
            ForEach(0..<boardData.size, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<boardData.size, id: \.self) { col in
                        let cellKey = "\(row),\(col)"
                        let isAttacked = attackedCells.contains(cellKey)
                        let airplane = airplanes.first { $0.hasCell(row: row, col: col) }
                        let cellType = airplane?.getCellType(row: row, col: col)
                        let isHit = isAttacked && airplane != nil

                        ReportCellView(
                            hasAirplane: airplane != nil,
                            cellType: cellType,
                            isAttacked: isAttacked,
                            isHit: isHit,
                            isDestroyed: airplane?.isDestroyed ?? false,
                            cellSize: cellSize,
                            themeColors: themeColors
                        )
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(AppColors.accentBorder, lineWidth: 1)
        )
    }
}

struct ReportCellView: View {
    let hasAirplane: Bool
    let cellType: AirplaneCellType?
    let isAttacked: Bool
    let isHit: Bool
    let isDestroyed: Bool
    let cellSize: CGFloat
    let themeColors: ThemeColors

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: cellSize, height: cellSize)

            if isAttacked {
                if isHit {
                    Image(systemName: "flame.fill")
                        .font(.system(size: cellSize * 0.5))
                        .foregroundColor(.orange)
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: cellSize * 0.3, height: cellSize * 0.3)
                }
            }

            if cellType == .head && hasAirplane {
                Circle()
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: cellSize * 0.6, height: cellSize * 0.6)
            }
        }
        .overlay(
            Rectangle()
                .stroke(AppColors.borderLight, lineWidth: 0.5)
        )
    }

    private var backgroundColor: Color {
        if isDestroyed && hasAirplane {
            return Color(hex: themeColors.cellKilled)
        } else if isHit {
            return Color(hex: themeColors.cellHit)
        } else if isAttacked && !hasAirplane {
            return GridCellColors.miss
        } else if hasAirplane {
            return GridCellColors.ship
        }
        return GridCellColors.water
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppFonts.rajdhani(15, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct InfoBadge: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(AppFonts.tag)
        }
        .foregroundColor(Color.white.opacity(0.8))
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(AppColors.accentDim)
        )
        .overlay(
            Capsule()
                .stroke(AppColors.accentBorder, lineWidth: 1)
        )
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppFonts.medNumber)
                .foregroundColor(.white)
        }
    }
}

struct PlayerCard: View {
    let name: String
    let isWinner: Bool
    let stats: GameStats?

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(name)
                    .font(AppFonts.orbitron(13, weight: .semibold))
                    .foregroundColor(.white)
                if isWinner {
                    Text("\u{1F451}")
                }
            }

            if let stats = stats {
                HStack(spacing: 20) {
                    VStack {
                        Text("\(stats.hits)")
                            .font(AppFonts.bigNumber)
                            .foregroundColor(isWinner ? AppColors.accent : AppColors.danger)
                        Text("HITS")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textMuted)
                            .tracking(1)
                    }
                    VStack {
                        Text("\(stats.kills)")
                            .font(AppFonts.bigNumber)
                            .foregroundColor(isWinner ? AppColors.accent : AppColors.danger)
                        Text("KILLS")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textMuted)
                            .tracking(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isWinner ? AppColors.accentSoft : Color(red: 0, green: 30/255, blue: 60/255).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isWinner ? AppColors.accentBorder.opacity(0.8) : AppColors.accentBorder.opacity(0.5), lineWidth: isWinner ? 2 : 1)
        )
        .shadow(color: isWinner ? AppColors.accentGlow.opacity(0.15) : .clear, radius: 15, x: 0, y: 0)
    }
}
