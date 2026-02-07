import SwiftUI

/// Board view for airplane deployment phase
struct DeploymentBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedDirection: GameConstants.Direction = .up
    @State private var isDragging = false
    @State private var dragHeadRow: Int = -1
    @State private var dragHeadCol: Int = -1
    @State private var showPlacementError = false
    @State private var gridOriginInGlobal: CGPoint = .zero
    private let themeColors = SkinDefinitions.currentThemeColors()

    private var boardSize: Int {
        viewModel.playerBoard?.size ?? 10
    }

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 60
        let size = availableWidth / CGFloat(boardSize)
        return min(max(size, GameConstants.GridDisplay.minCellSize), GameConstants.GridDisplay.maxCellSize)
    }

    private let labelOffsetX: CGFloat = 24
    private let labelOffsetY: CGFloat = 16

    private var boardWidth: CGFloat {
        labelOffsetX + CGFloat(boardSize) * cellSize
    }

    private var boardHeight: CGFloat {
        labelOffsetY + CGFloat(boardSize) * cellSize
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Deploy Your Fleet")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("\(viewModel.deployedAirplanes.count)/\(viewModel.playerBoard?.airplaneCount ?? 3) airplanes placed")
                .font(.caption)
                .foregroundColor(.gray)

            // 棋盘区域
            if let board = viewModel.playerBoard {
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        boardGrid(board: board)

                        if isDragging && dragHeadRow >= -2 && dragHeadCol >= -2 {
                            dragPreviewOverlay(board: board)
                                .allowsHitTesting(false)
                        }
                    }
                    .onAppear {
                        gridOriginInGlobal = geo.frame(in: .global).origin
                    }
                    .onChange(of: geo.frame(in: .global).origin) { newOrigin in
                        gridOriginInGlobal = newOrigin
                    }
                }
                .frame(width: boardWidth, height: boardHeight)
            }

            // 错误提示
            Text(showPlacementError ? "Cannot place airplane here" : " ")
                .font(.caption)
                .foregroundColor(.red)
                .frame(height: 20)

            // 控制区域 - 居中布局
            VStack(spacing: 16) {
                // 飞机预览和旋转按钮
                HStack(spacing: 20) {
                    // 可拖拽的飞机格子预览
                    airplanePreview
                        .opacity(isDragging ? 0.3 : 1.0)
                        .gesture(
                            DragGesture(coordinateSpace: .global)
                                .onChanged { value in
                                    isDragging = true
                                    updateDragPosition(globalLocation: value.location)
                                }
                                .onEnded { _ in
                                    placeDraggedAirplane()
                                    isDragging = false
                                    dragHeadRow = -1
                                    dragHeadCol = -1
                                }
                        )

                    Button(action: rotateDirection) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title2)
                            Text("Rotate")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.bordered)
                }

                // 操作按钮
                HStack(spacing: 16) {
                    Button(action: { viewModel.deployAirplanesRandomly() }) {
                        Label("Random", systemImage: "dice.fill")
                    }
                    .buttonStyle(.bordered)

                    Button(action: { viewModel.clearDeployment() }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                // 开始战斗按钮
                if viewModel.isDeploymentComplete() {
                    Button("Start Battle") {
                        viewModel.confirmDeployment()
                    }
                    .font(.headline)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }

            Text("Drag airplane to board or tap cell")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
    }

    // 飞机格子预览（简单的格子显示）
    @ViewBuilder
    private var airplanePreview: some View {
        let previewCellSize: CGFloat = 18
        let cells = Airplane.calculateCells(headRow: 3, headCol: 3, direction: selectedDirection)
        let minRow = cells.map(\.row).min() ?? 0
        let minCol = cells.map(\.col).min() ?? 0
        let maxRow = cells.map(\.row).max() ?? 0
        let maxCol = cells.map(\.col).max() ?? 0
        let rows = maxRow - minRow + 1
        let cols = maxCol - minCol + 1

        VStack(spacing: 1) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 1) {
                    ForEach(0..<cols, id: \.self) { c in
                        let row = r + minRow
                        let col = c + minCol
                        let cell = cells.first { $0.row == row && $0.col == col }

                        if let cell = cell {
                            RoundedRectangle(cornerRadius: cell.type == .head ? previewCellSize / 2 : 2)
                                .fill(cell.type == .head ? Color.cyan : Color(hex: SkinDefinitions.currentSkinColor()))
                                .frame(width: previewCellSize, height: previewCellSize)
                                .overlay(
                                    Group {
                                        if cell.type == .head {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 1)
                                                .frame(width: previewCellSize * 0.6, height: previewCellSize * 0.6)
                                        }
                                    }
                                )
                        } else {
                            Color.clear
                                .frame(width: previewCellSize, height: previewCellSize)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dragPreviewOverlay(board: BoardManager) -> some View {
        let cells = Airplane.calculateCells(headRow: dragHeadRow, headCol: dragHeadCol, direction: selectedDirection)
        let isValid = isPlacementValid(board: board, cells: cells)

        ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
            if cell.row >= 0 && cell.row < board.size && cell.col >= 0 && cell.col < board.size {
                Rectangle()
                    .fill(isValid ? Color.green.opacity(0.6) : Color.red.opacity(0.6))
                    .frame(width: cellSize - 2, height: cellSize - 2)
                    .overlay(
                        Group {
                            if cell.type == .head {
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            }
                        }
                    )
                    .position(
                        x: labelOffsetX + CGFloat(cell.col) * cellSize + cellSize / 2,
                        y: labelOffsetY + CGFloat(cell.row) * cellSize + cellSize / 2
                    )
            }
        }
    }

    private func isPlacementValid(board: BoardManager, cells: [AirplaneCell]) -> Bool {
        if board.airplanes.count >= board.airplaneCount {
            return false
        }

        for cell in cells {
            if cell.row < 0 || cell.row >= board.size || cell.col < 0 || cell.col >= board.size {
                return false
            }
            if board.hasAirplaneAt(row: cell.row, col: cell.col) {
                return false
            }
        }
        return true
    }

    @ViewBuilder
    private func boardGrid(board: BoardManager) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear.frame(width: labelOffsetX, height: labelOffsetY)
                ForEach(0..<board.size, id: \.self) { col in
                    Text(CoordinateSystem.indexToLetter(col))
                        .font(.system(size: min(cellSize * 0.4, 10)))
                        .foregroundColor(.gray)
                        .frame(width: cellSize, height: labelOffsetY)
                }
            }

            ForEach(0..<board.size, id: \.self) { row in
                HStack(spacing: 0) {
                    Text("\(row + 1)")
                        .font(.system(size: min(cellSize * 0.4, 10)))
                        .foregroundColor(.gray)
                        .frame(width: labelOffsetX, height: cellSize)

                    ForEach(0..<board.size, id: \.self) { col in
                        cellView(board: board, row: row, col: col)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(board: BoardManager, row: Int, col: Int) -> some View {
        let airplane = board.getAirplaneAt(row: row, col: col)

        ZStack {
            if let airplane = airplane,
               let cellType = airplane.getCellType(row: row, col: col) {
                AirplaneCellView(type: cellType, cellSize: cellSize, showDetailed: true)
                    .overlay(
                        Group {
                            if cellType == .head {
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: cellSize * 0.6, height: cellSize * 0.6)
                            }
                        }
                    )
            } else {
                Rectangle()
                    .fill(Color(hex: themeColors.cellEmpty))
            }
        }
        .frame(width: cellSize, height: cellSize)
        .overlay(
            Rectangle()
                .stroke(Color(hex: themeColors.gridLine), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            handleCellTap(board: board, row: row, col: col)
        }
    }

    private func updateDragPosition(globalLocation: CGPoint) {
        let relativeX = globalLocation.x - gridOriginInGlobal.x - labelOffsetX
        let relativeY = globalLocation.y - gridOriginInGlobal.y - labelOffsetY

        // 手指指向机头位置（不加偏移，更直观）
        let col = Int(relativeX / cellSize)
        let row = Int(relativeY / cellSize)

        dragHeadRow = row
        dragHeadCol = col
    }

    private func placeDraggedAirplane() {
        guard let board = viewModel.playerBoard else { return }

        let row = dragHeadRow
        let col = dragHeadCol

        guard row >= 0 && row < board.size && col >= 0 && col < board.size else {
            return
        }

        let success = viewModel.addAirplane(headRow: row, headCol: col, direction: selectedDirection)

        if !success {
            showPlacementError = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showPlacementError = false
            }
        }
    }

    private func handleCellTap(board: BoardManager, row: Int, col: Int) {
        if let airplane = board.getAirplaneAt(row: row, col: col) {
            viewModel.removeAirplane(id: airplane.id)
            return
        }

        let success = viewModel.addAirplane(headRow: row, headCol: col, direction: selectedDirection)
        if !success {
            showPlacementError = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showPlacementError = false
            }
        }
    }

    private func rotateDirection() {
        let allDirs = GameConstants.Direction.allCases
        if let index = allDirs.firstIndex(of: selectedDirection) {
            selectedDirection = allDirs[(index + 1) % allDirs.count]
        }
    }
}

struct GridOriginPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}
