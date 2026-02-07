import SwiftUI

struct BattleReportView: View {
    @Binding var navigationPath: NavigationPath
    let gameData: GameHistoryEntry
    private let themeColors = SkinDefinitions.currentThemeColors()

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = (screenWidth - 80) / 2  // 两个棋盘并排
        return min(max(availableWidth / CGFloat(gameData.boardSize), 12), 20)
    }

    // 游戏时长估算（每回合约30秒）
    private var estimatedDuration: String {
        let seconds = gameData.totalTurns * 30
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        }
        return "\(seconds)s"
    }

    // 效率计算（命中率）
    private var playerEfficiency: String {
        guard let stats = gameData.playerStats else { return "N/A" }
        let total = stats.hits + stats.misses
        guard total > 0 else { return "0%" }
        let efficiency = Double(stats.hits) / Double(total) * 100
        return String(format: "%.1f%%", efficiency)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Result
                    HStack {
                        Image(systemName: gameData.winner == gameData.userId ? "trophy.fill" : "xmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(gameData.winner == gameData.userId ? .yellow : .red)
                        Text(gameData.winner == gameData.userId ? "VICTORY" : "DEFEAT")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(gameData.winner == gameData.userId ? .green : .red)
                    }

                    // Game summary
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            InfoBadge(icon: "square.grid.3x3", value: "\(gameData.boardSize)×\(gameData.boardSize)")
                            InfoBadge(icon: "airplane", value: "\(gameData.airplaneCount)")
                            InfoBadge(icon: "arrow.triangle.2.circlepath", value: "\(gameData.totalTurns) turns")
                        }
                        HStack(spacing: 16) {
                            InfoBadge(icon: "clock", value: "~\(estimatedDuration)")
                            InfoBadge(icon: "target", value: "\(playerEfficiency) hit rate")
                        }
                    }

                    // Players section
                    HStack(spacing: 12) {
                        PlayerCard(
                            name: "You",
                            isWinner: gameData.winner == gameData.userId,
                            stats: gameData.playerStats
                        )

                        PlayerCard(
                            name: gameData.opponent,
                            isWinner: gameData.winner != gameData.userId,
                            stats: gameData.aiStats
                        )
                    }
                    .padding(.horizontal)

                    // Battle Boards - 双方棋盘对比
                    if gameData.playerBoardData != nil || gameData.aiBoardData != nil {
                        VStack(spacing: 12) {
                            Text("Battle Map")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack(alignment: .top, spacing: 16) {
                                // 玩家棋盘（被攻击情况）
                                VStack(spacing: 4) {
                                    Text("Your Fleet")
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                    if let boardData = gameData.playerBoardData {
                                        ReportBoardView(
                                            boardData: boardData,
                                            cellSize: cellSize,
                                            themeColors: themeColors,
                                            isPlayerBoard: true
                                        )
                                    }
                                }

                                // 对手棋盘（你的攻击情况）
                                VStack(spacing: 4) {
                                    Text("Enemy Fleet")
                                        .font(.caption.bold())
                                        .foregroundColor(.cyan)
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
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Stats comparison
                    HStack(alignment: .top, spacing: 16) {
                        // Player stats
                        if let stats = gameData.playerStats {
                            VStack(spacing: 8) {
                                Text("Your Stats")
                                    .font(.caption.bold())
                                    .foregroundColor(.cyan)
                                StatItem(icon: "flame.fill", label: "Hits", value: "\(stats.hits)", color: .orange)
                                StatItem(icon: "circle", label: "Misses", value: "\(stats.misses)", color: .gray)
                                StatItem(icon: "xmark.circle.fill", label: "Kills", value: "\(stats.kills)", color: .red)
                                let total = stats.hits + stats.misses
                                if total > 0 {
                                    StatItem(icon: "target", label: "Accuracy",
                                            value: String(format: "%.0f%%", Double(stats.hits) / Double(total) * 100),
                                            color: .green)
                                }
                            }
                            .padding()
                            .background(Color.cyan.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // AI stats
                        if let aiStats = gameData.aiStats {
                            VStack(spacing: 8) {
                                Text("Opponent Stats")
                                    .font(.caption.bold())
                                    .foregroundColor(.orange)
                                StatItem(icon: "flame.fill", label: "Hits", value: "\(aiStats.hits)", color: .orange)
                                StatItem(icon: "circle", label: "Misses", value: "\(aiStats.misses)", color: .gray)
                                StatItem(icon: "xmark.circle.fill", label: "Kills", value: "\(aiStats.kills)", color: .red)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }

                    // Match details
                    VStack(spacing: 8) {
                        InfoRow(label: "Opponent", value: gameData.opponent)
                        InfoRow(label: "Type", value: gameData.gameType == "ai" ? "vs AI" : "Online")
                        InfoRow(label: "Date", value: formatDate(gameData.completedAt))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationTitle("Battle Report")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Unlock "Data Analyst" achievement when viewing battle report
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

// 战报棋盘视图 - 显示飞机位置和攻击点
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
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
}

// 战报单元格视图
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
            // 背景色
            Rectangle()
                .fill(backgroundColor)
                .frame(width: cellSize, height: cellSize)

            // 攻击标记
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

            // 机头标记
            if cellType == .head && hasAirplane {
                Circle()
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: cellSize * 0.6, height: cellSize * 0.6)
            }
        }
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
    }

    private var backgroundColor: Color {
        if isDestroyed && hasAirplane {
            return Color(hex: themeColors.cellKilled)
        } else if isHit {
            return Color(hex: themeColors.cellHit)
        } else if isAttacked && !hasAirplane {
            return Color(hex: themeColors.cellMiss)
        } else if hasAirplane {
            return Color(hex: SkinDefinitions.currentSkinColor()).opacity(0.7)
        }
        return Color(hex: themeColors.cellEmpty)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
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
                .font(.caption.bold())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.3))
        .cornerRadius(8)
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
                .foregroundColor(.gray)
                .font(.caption)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .font(.caption.bold())
        }
    }
}

// 玩家信息卡片（胜者高亮）
struct PlayerCard: View {
    let name: String
    let isWinner: Bool
    let stats: GameStats?

    var body: some View {
        VStack(spacing: 8) {
            // 玩家名称
            HStack {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.white)
                if isWinner {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }

            // 简要统计
            if let stats = stats {
                HStack(spacing: 12) {
                    VStack {
                        Text("\(stats.hits)")
                            .font(.title2.bold())
                            .foregroundColor(.orange)
                        Text("Hits")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    VStack {
                        Text("\(stats.kills)")
                            .font(.title2.bold())
                            .foregroundColor(.red)
                        Text("Kills")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: isWinner ?
                    [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)] :
                    [Color.gray.opacity(0.1), Color.gray.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isWinner ? Color.yellow : Color.gray.opacity(0.3), lineWidth: isWinner ? 2 : 1)
        )
        .cornerRadius(12)
    }
}
