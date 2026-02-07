import SwiftUI

/// Battle view for online mode - handles attacks via Firebase
struct OnlineBattleView: View {
    @ObservedObject var viewModel: OnlineGameViewModel
    private let themeColors = SkinDefinitions.currentThemeColors()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

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
                    .fill(viewModel.isMyTurn ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(viewModel.isMyTurn ? "Your Turn - Tap to Attack" : "Opponent's Turn")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)

            // Opponent board (attack target) - 大棋盘
            VStack(spacing: 4) {
                HStack {
                    Text("Enemy Fleet (\(viewModel.opponentNickname))")
                        .font(.caption.bold())
                        .foregroundColor(.cyan)
                    Spacer()
                    Text("Tap to attack")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 30)

                OnlineBoardGridView(
                    viewModel: viewModel,
                    isOpponentBoard: true,
                    isInteractive: viewModel.isMyTurn,
                    themeColors: themeColors
                )
            }

            // 中间控制区：小棋盘 + 投降按钮
            HStack(alignment: .top, spacing: 12) {
                // Player board (show own airplanes and opponent's attacks) - 缩小的棋盘
                VStack(spacing: 4) {
                    HStack {
                        Text("Your Fleet")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        Spacer()
                    }
                    .padding(.horizontal, 8)

                    OnlineSmallBoardGridView(
                        viewModel: viewModel,
                        isOpponentBoard: false,
                        themeColors: themeColors
                    )
                }
                .frame(maxWidth: .infinity)

                // 右侧投降按钮
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
                .padding(.trailing, 8)
            }
            .padding(.horizontal)

            // Game log
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.gameLog.suffix(5), id: \.self) { log in
                        Text(log)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 60)
            .padding(.horizontal)
        }
    }

    // 横屏布局（适配屏幕）
    private var landscapeLayout: some View {
        VStack(spacing: 4) {
            // Turn indicator
            HStack {
                Circle()
                    .fill(viewModel.isMyTurn ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(viewModel.isMyTurn ? "Your Turn - Tap to Attack" : "Opponent's Turn")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // 投降按钮
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
                            Text("Enemy Fleet (\(viewModel.opponentNickname))")
                                .font(.caption.bold())
                                .foregroundColor(.cyan)
                            Spacer()
                        }
                        .padding(.horizontal, 8)

                        OnlineLandscapeBoardGridView(
                            viewModel: viewModel,
                            isOpponentBoard: true,
                            isInteractive: viewModel.isMyTurn,
                            themeColors: themeColors,
                            maxWidth: (geometry.size.width - 24) / 2,
                            maxHeight: geometry.size.height - 50
                        )
                    }

                    // Player board (show own airplanes and opponent's attacks)
                    VStack(spacing: 4) {
                        HStack {
                            Text("Your Fleet")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding(.horizontal, 8)

                        OnlineLandscapeBoardGridView(
                            viewModel: viewModel,
                            isOpponentBoard: false,
                            isInteractive: false,
                            themeColors: themeColors,
                            maxWidth: (geometry.size.width - 24) / 2,
                            maxHeight: geometry.size.height - 50
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Game log (compact in landscape)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.gameLog.suffix(5), id: \.self) { log in
                        Text(log)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 40)
            .padding(.horizontal)
        }
    }
}

/// Grid view for online battles
struct OnlineBoardGridView: View {
    @ObservedObject var viewModel: OnlineGameViewModel
    let isOpponentBoard: Bool
    let isInteractive: Bool
    let themeColors: ThemeColors

    private var boardSize: Int {
        viewModel.deploymentHelper.playerBoard?.size ?? 10
    }

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 60
        let size = availableWidth / CGFloat(boardSize)
        return min(max(size, 20), 35)
    }

    private let labelOffsetX: CGFloat = 20
    private let labelOffsetY: CGFloat = 14

    // Cache board size to reduce recalculation
    private var boardId: String {
        "\(isOpponentBoard)-\(boardSize)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Column labels
            HStack(spacing: 0) {
                Color.clear.frame(width: labelOffsetX, height: labelOffsetY)
                ForEach(0..<boardSize, id: \.self) { col in
                    Text(CoordinateSystem.indexToLetter(col))
                        .font(.system(size: min(cellSize * 0.35, 9)))
                        .foregroundColor(.gray)
                        .frame(width: cellSize, height: labelOffsetY)
                }
            }

            // Rows
            ForEach(0..<boardSize, id: \.self) { row in
                HStack(spacing: 0) {
                    Text("\(row + 1)")
                        .font(.system(size: min(cellSize * 0.35, 9)))
                        .foregroundColor(.gray)
                        .frame(width: labelOffsetX, height: cellSize)

                    ForEach(0..<boardSize, id: \.self) { col in
                        OnlineCellView(
                            viewModel: viewModel,
                            row: row,
                            col: col,
                            isOpponentBoard: isOpponentBoard,
                            cellSize: cellSize,
                            themeColors: themeColors
                        )
                        .id("\(row)-\(col)-\(boardId)")
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isInteractive && isOpponentBoard {
                                viewModel.attack(row: row, col: col)
                            }
                        }
                    }
                }
            }
        }
        .drawingGroup() // Performance optimization for large grids
    }
}

/// Single cell view for online battles
struct OnlineCellView: View {
    let viewModel: OnlineGameViewModel
    let row: Int
    let col: Int
    let isOpponentBoard: Bool
    let cellSize: CGFloat
    let themeColors: ThemeColors

    private var cellKey: String {
        "\(row),\(col)"
    }

    private var attackResult: String? {
        if isOpponentBoard {
            return viewModel.myAttacks[cellKey]
        } else {
            return viewModel.opponentAttacks[cellKey]
        }
    }

    var body: some View {
        ZStack {
            // Background - color based on attack result
            Rectangle()
                .fill(backgroundColor)

            // Show airplane for own board
            if !isOpponentBoard {
                if let board = viewModel.deploymentHelper.playerBoard,
                   let airplane = board.getAirplaneAt(row: row, col: col),
                   let cellType = airplane.getCellType(row: row, col: col) {
                    AirplaneCellView(type: cellType, cellSize: cellSize, showDetailed: true)
                }
            }

            // Show attack result markers
            if let result = attackResult {
                attackMarker(for: result)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .overlay(
            Rectangle()
                .stroke(Color(hex: themeColors.gridLine), lineWidth: 0.5)
        )
    }

    private var backgroundColor: Color {
        if let result = attackResult {
            switch result {
            case "hit":
                return Color.orange.opacity(0.5)
            case "kill":
                return Color.red.opacity(0.6)
            case "miss":
                return Color.blue.opacity(0.3)
            default:
                return Color(hex: themeColors.cellEmpty)
            }
        }
        return Color(hex: themeColors.cellEmpty)
    }

    @ViewBuilder
    private func attackMarker(for result: String) -> some View {
        switch result {
        case "hit":
            Image(systemName: "flame.fill")
                .font(.system(size: cellSize * 0.5))
                .foregroundColor(.orange)
        case "kill":
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: cellSize * 0.6))
                .foregroundColor(.red)
        case "miss":
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: cellSize * 0.3, height: cellSize * 0.3)
        default:
            EmptyView()
        }
    }
}

// 缩小的在线棋盘视图（用于竖屏下方的小棋盘）
struct OnlineSmallBoardGridView: View {
    @ObservedObject var viewModel: OnlineGameViewModel
    let isOpponentBoard: Bool
    let themeColors: ThemeColors

    private var boardSize: Int {
        viewModel.deploymentHelper.playerBoard?.size ?? 10
    }

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = (screenWidth - 100) / 2
        return min(max(availableWidth / CGFloat(boardSize), 10), 20)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<boardSize, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<boardSize, id: \.self) { col in
                        OnlineSmallCellView(
                            viewModel: viewModel,
                            row: row,
                            col: col,
                            isOpponentBoard: isOpponentBoard,
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
struct OnlineSmallCellView: View {
    let viewModel: OnlineGameViewModel
    let row: Int
    let col: Int
    let isOpponentBoard: Bool
    let cellSize: CGFloat
    let themeColors: ThemeColors

    private var cellKey: String {
        "\(row),\(col)"
    }

    private var attackResult: String? {
        if isOpponentBoard {
            return viewModel.myAttacks[cellKey]
        } else {
            return viewModel.opponentAttacks[cellKey]
        }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)

            // Show airplane for own board
            if !isOpponentBoard {
                if let board = viewModel.deploymentHelper.playerBoard,
                   let airplane = board.getAirplaneAt(row: row, col: col),
                   let cellType = airplane.getCellType(row: row, col: col) {
                    AirplaneCellView(type: cellType, cellSize: cellSize, showDetailed: false)
                }
            }

            // Show attack result markers
            if let result = attackResult {
                smallAttackMarker(for: result)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .overlay(
            Rectangle()
                .stroke(Color(hex: themeColors.gridLine), lineWidth: 0.5)
        )
    }

    private var backgroundColor: Color {
        if let result = attackResult {
            switch result {
            case "hit":
                return Color.orange.opacity(0.5)
            case "kill":
                return Color.red.opacity(0.6)
            case "miss":
                return Color.blue.opacity(0.3)
            default:
                return Color(hex: themeColors.cellEmpty)
            }
        }
        return Color(hex: themeColors.cellEmpty)
    }

    @ViewBuilder
    private func smallAttackMarker(for result: String) -> some View {
        switch result {
        case "hit":
            Circle()
                .fill(Color.orange)
                .frame(width: cellSize * 0.5, height: cellSize * 0.5)
        case "kill":
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: cellSize * 0.6))
                .foregroundColor(.red)
        case "miss":
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: cellSize * 0.3, height: cellSize * 0.3)
        default:
            EmptyView()
        }
    }
}

// 横屏适配的在线棋盘视图
struct OnlineLandscapeBoardGridView: View {
    @ObservedObject var viewModel: OnlineGameViewModel
    let isOpponentBoard: Bool
    let isInteractive: Bool
    let themeColors: ThemeColors
    let maxWidth: CGFloat
    let maxHeight: CGFloat

    private var boardSize: Int {
        viewModel.deploymentHelper.playerBoard?.size ?? 10
    }

    private var cellSize: CGFloat {
        let sizeByWidth = maxWidth / CGFloat(boardSize)
        let sizeByHeight = maxHeight / CGFloat(boardSize)
        return min(sizeByWidth, sizeByHeight, 30)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<boardSize, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<boardSize, id: \.self) { col in
                        OnlineLandscapeCellView(
                            viewModel: viewModel,
                            row: row,
                            col: col,
                            isOpponentBoard: isOpponentBoard,
                            cellSize: cellSize,
                            themeColors: themeColors
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isInteractive && isOpponentBoard {
                                viewModel.attack(row: row, col: col)
                            }
                        }
                    }
                }
            }
        }
    }
}

// 横屏单元格视图
struct OnlineLandscapeCellView: View {
    let viewModel: OnlineGameViewModel
    let row: Int
    let col: Int
    let isOpponentBoard: Bool
    let cellSize: CGFloat
    let themeColors: ThemeColors

    private var cellKey: String {
        "\(row),\(col)"
    }

    private var attackResult: String? {
        if isOpponentBoard {
            return viewModel.myAttacks[cellKey]
        } else {
            return viewModel.opponentAttacks[cellKey]
        }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)

            // Show airplane for own board
            if !isOpponentBoard {
                if let board = viewModel.deploymentHelper.playerBoard,
                   let airplane = board.getAirplaneAt(row: row, col: col),
                   let cellType = airplane.getCellType(row: row, col: col) {
                    AirplaneCellView(type: cellType, cellSize: cellSize, showDetailed: true)
                }
            }

            // Show attack result markers
            if let result = attackResult {
                landscapeAttackMarker(for: result)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .overlay(
            Rectangle()
                .stroke(Color(hex: themeColors.gridLine), lineWidth: 0.5)
        )
    }

    private var backgroundColor: Color {
        if let result = attackResult {
            switch result {
            case "hit":
                return Color.orange.opacity(0.5)
            case "kill":
                return Color.red.opacity(0.6)
            case "miss":
                return Color.blue.opacity(0.3)
            default:
                return Color(hex: themeColors.cellEmpty)
            }
        }
        return Color(hex: themeColors.cellEmpty)
    }

    @ViewBuilder
    private func landscapeAttackMarker(for result: String) -> some View {
        switch result {
        case "hit":
            Image(systemName: "flame.fill")
                .font(.system(size: cellSize * 0.5))
                .foregroundColor(.orange)
        case "kill":
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: cellSize * 0.6))
                .foregroundColor(.red)
        case "miss":
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: cellSize * 0.3, height: cellSize * 0.3)
        default:
            EmptyView()
        }
    }
}
