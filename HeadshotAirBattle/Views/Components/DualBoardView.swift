import SwiftUI

/// Dual board layout for battle phase - shows opponent board (interactive) and player board (reveal)
struct DualBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    private let themeColors = SkinDefinitions.currentThemeColors()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    // 使用 totalTurns 作为刷新触发器，确保每次攻击后视图刷新
    private var refreshTrigger: Int {
        viewModel.totalTurns
    }

    // 检测是否为横屏
    private var isLandscape: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact
    }

    var body: some View {
        Group {
            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
    }

    // 竖屏布局（新布局：缩小下方棋盘，投降按钮在中间）
    private var portraitLayout: some View {
        VStack(spacing: 8) {
            // Turn indicator
            HStack {
                Circle()
                    .fill(viewModel.isPlayerTurn ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(viewModel.isPlayerTurn ? "Your Turn" : "Opponent's Turn")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)

            // Opponent board (attack target) - 大棋盘
            VStack(spacing: 4) {
                HStack {
                    Text("Enemy Fleet")
                        .font(.caption.bold())
                        .foregroundColor(.cyan)
                    Spacer()
                    if let board = viewModel.opponentBoard {
                        Text("Remaining: \(board.getRemainingAirplaneCount())")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 30)

                if let board = viewModel.opponentBoard {
                    BoardGridView(
                        board: board,
                        revealAirplanes: false,
                        isInteractive: viewModel.isPlayerTurn,
                        themeColors: themeColors,
                        onCellTap: { row, col in
                            viewModel.playerAttack(row: row, col: col)
                        }
                    )
                    .id(refreshTrigger)
                }
            }

            // 中间控制区：小棋盘 + 投降按钮/计时器
            HStack(alignment: .top, spacing: 12) {
                // Player board (reveal own airplanes) - 缩小的棋盘
                VStack(spacing: 4) {
                    HStack {
                        Text("Your Fleet")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        Spacer()
                        if let board = viewModel.playerBoard {
                            Text("Remaining: \(board.getRemainingAirplaneCount())")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 8)

                    if let board = viewModel.playerBoard {
                        SmallBoardGridView(
                            board: board,
                            revealAirplanes: true,
                            themeColors: themeColors
                        )
                        .id(refreshTrigger)
                    }
                }
                .frame(maxWidth: .infinity)

                // 右侧控制按钮
                VStack(spacing: 12) {
                    // Timer
                    TurnTimerView(timeRemaining: viewModel.turnTimeRemaining)

                    // Surrender button
                    Button(action: {
                        viewModel.surrender()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "flag.fill")
                                .font(.title2)
                            Text("Surrender")
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                    }
                }
                .padding(.trailing, 8)
            }
            .padding(.horizontal)

            // Game log
            GameLogView(logs: viewModel.gameLog)
        }
    }

    // 横屏布局（棋盘左右排列，适配屏幕）
    private var landscapeLayout: some View {
        VStack(spacing: 4) {
            // Turn indicator
            HStack {
                Circle()
                    .fill(viewModel.isPlayerTurn ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(viewModel.isPlayerTurn ? "Your Turn" : "Opponent's Turn")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // Timer
                TurnTimerView(timeRemaining: viewModel.turnTimeRemaining)

                // Surrender button
                Button(action: {
                    viewModel.surrender()
                }) {
                    Text("Surrender")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)

            GeometryReader { geometry in
                HStack(spacing: 12) {
                    // Opponent board (attack target)
                    VStack(spacing: 4) {
                        HStack {
                            Text("Enemy Fleet")
                                .font(.caption.bold())
                                .foregroundColor(.cyan)
                            Spacer()
                            if let board = viewModel.opponentBoard {
                                Text("Remaining: \(board.getRemainingAirplaneCount())")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 8)

                        if let board = viewModel.opponentBoard {
                            LandscapeBoardGridView(
                                board: board,
                                revealAirplanes: false,
                                isInteractive: viewModel.isPlayerTurn,
                                themeColors: themeColors,
                                maxWidth: (geometry.size.width - 24) / 2,
                                maxHeight: geometry.size.height - 50,
                                refreshTrigger: refreshTrigger,
                                onCellTap: { row, col in
                                    viewModel.playerAttack(row: row, col: col)
                                }
                            )
                        }
                    }

                    // Player board (reveal own airplanes)
                    VStack(spacing: 4) {
                        HStack {
                            Text("Your Fleet")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                            Spacer()
                            if let board = viewModel.playerBoard {
                                Text("Remaining: \(board.getRemainingAirplaneCount())")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 8)

                        if let board = viewModel.playerBoard {
                            LandscapeBoardGridView(
                                board: board,
                                revealAirplanes: true,
                                isInteractive: false,
                                themeColors: themeColors,
                                maxWidth: (geometry.size.width - 24) / 2,
                                maxHeight: geometry.size.height - 50,
                                refreshTrigger: refreshTrigger,
                                onCellTap: nil
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Game log (compact in landscape)
            GameLogView(logs: viewModel.gameLog)
                .frame(height: 40)
        }
    }
}

// 缩小的棋盘视图（用于竖屏下方的小棋盘）
struct SmallBoardGridView: View {
    let board: BoardManager
    let revealAirplanes: Bool
    let themeColors: ThemeColors

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = (screenWidth - 100) / 2
        return min(max(availableWidth / CGFloat(board.size), 10), 20)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<board.size, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<board.size, id: \.self) { col in
                        SmallCellView(
                            board: board,
                            row: row,
                            col: col,
                            revealAirplanes: revealAirplanes,
                            cellSize: cellSize,
                            themeColors: themeColors
                        )
                    }
                }
            }
        }
    }
}

// 小棋盘的单元格视图
struct SmallCellView: View {
    let board: BoardManager
    let row: Int
    let col: Int
    let revealAirplanes: Bool
    let cellSize: CGFloat
    let themeColors: ThemeColors

    private var cellState: GameConstants.CellState {
        board.getCellState(row: row, col: col)
    }

    private var hasAirplane: Bool {
        board.getAirplaneAt(row: row, col: col) != nil
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)

            // Show airplane for revealed cells
            if revealAirplanes && hasAirplane {
                if let airplane = board.getAirplaneAt(row: row, col: col),
                   let cellType = airplane.getCellType(row: row, col: col) {
                    AirplaneCellView(type: cellType, cellSize: cellSize, showDetailed: false)
                }
            }

            // Show attack result markers
            if cellState == .hit {
                Circle()
                    .fill(Color.orange)
                    .frame(width: cellSize * 0.5, height: cellSize * 0.5)
            } else if cellState == .miss {
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: cellSize * 0.3, height: cellSize * 0.3)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .overlay(
            Rectangle()
                .stroke(Color(hex: themeColors.gridLine), lineWidth: 0.5)
        )
    }

    private var backgroundColor: Color {
        switch cellState {
        case .empty:
            return Color(hex: themeColors.cellEmpty)
        case .airplane:
            if revealAirplanes {
                return Color(hex: SkinDefinitions.currentSkinColor()).opacity(0.7)
            }
            return Color(hex: themeColors.cellEmpty)
        case .hit:
            return Color(hex: themeColors.cellHit)
        case .miss:
            return Color(hex: themeColors.cellMiss)
        case .killed:
            return Color(hex: themeColors.cellKilled)
        }
    }
}

// 横屏适配的棋盘视图（根据可用空间计算大小）
struct LandscapeBoardGridView: View {
    let board: BoardManager
    let revealAirplanes: Bool
    let isInteractive: Bool
    let themeColors: ThemeColors
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let refreshTrigger: Int
    let onCellTap: ((Int, Int) -> Void)?

    private var cellSize: CGFloat {
        let sizeByWidth = maxWidth / CGFloat(board.size)
        let sizeByHeight = maxHeight / CGFloat(board.size)
        return min(sizeByWidth, sizeByHeight, 30)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<board.size, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<board.size, id: \.self) { col in
                        LandscapeCellView(
                            board: board,
                            row: row,
                            col: col,
                            revealAirplanes: revealAirplanes,
                            cellSize: cellSize,
                            themeColors: themeColors
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isInteractive {
                                onCellTap?(row, col)
                            }
                        }
                    }
                }
            }
        }
        .id(refreshTrigger)
    }
}

// 横屏单元格视图
struct LandscapeCellView: View {
    let board: BoardManager
    let row: Int
    let col: Int
    let revealAirplanes: Bool
    let cellSize: CGFloat
    let themeColors: ThemeColors

    private var cellState: GameConstants.CellState {
        board.getCellState(row: row, col: col)
    }

    private var hasAirplane: Bool {
        board.getAirplaneAt(row: row, col: col) != nil
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)

            // Show airplane for revealed cells
            if revealAirplanes && hasAirplane {
                if let airplane = board.getAirplaneAt(row: row, col: col),
                   let cellType = airplane.getCellType(row: row, col: col) {
                    AirplaneCellView(type: cellType, cellSize: cellSize, showDetailed: true)
                }
            }

            // Show attack result markers
            if cellState == .hit {
                Image(systemName: "flame.fill")
                    .font(.system(size: cellSize * 0.5))
                    .foregroundColor(.orange)
            } else if cellState == .miss {
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: cellSize * 0.3, height: cellSize * 0.3)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .overlay(
            Rectangle()
                .stroke(Color(hex: themeColors.gridLine), lineWidth: 0.5)
        )
    }

    private var backgroundColor: Color {
        switch cellState {
        case .empty:
            return Color(hex: themeColors.cellEmpty)
        case .airplane:
            if revealAirplanes {
                return Color(hex: SkinDefinitions.currentSkinColor()).opacity(0.7)
            }
            return Color(hex: themeColors.cellEmpty)
        case .hit:
            return Color(hex: themeColors.cellHit)
        case .miss:
            return Color(hex: themeColors.cellMiss)
        case .killed:
            return Color(hex: themeColors.cellKilled)
        }
    }
}
