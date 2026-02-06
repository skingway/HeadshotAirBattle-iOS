import SwiftUI

/// Board view for airplane deployment phase - drag from airplane icon to board
struct DeploymentBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedDirection: GameConstants.Direction = .up
    @State private var isDragging = false
    @State private var dragHeadRow: Int = -1
    @State private var dragHeadCol: Int = -1
    @State private var showPlacementError = false
    @State private var gridOriginInGlobal: CGPoint = .zero
    private let themeColors = SkinDefinitions.currentThemeColors()

    private var cellSize: CGFloat {
        let boardSize = viewModel.playerBoard?.size ?? 10
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 60
        let size = availableWidth / CGFloat(boardSize)
        return min(max(size, GameConstants.GridDisplay.minCellSize), GameConstants.GridDisplay.maxCellSize)
    }

    // 标签偏移量
    private let labelOffsetX: CGFloat = 24
    private let labelOffsetY: CGFloat = 16

    var body: some View {
        VStack(spacing: 12) {
            Text("Deploy Your Fleet")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("\(viewModel.deployedAirplanes.count)/\(viewModel.playerBoard?.airplaneCount ?? 3) airplanes placed")
                .font(.caption)
                .foregroundColor(.gray)

            // Board
            if let board = viewModel.playerBoard {
                ZStack(alignment: .topLeading) {
                    // 棋盘网格
                    boardGrid(board: board)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: GridOriginPreferenceKey.self,
                                    value: geo.frame(in: .global).origin
                                )
                            }
                        )
                        .onPreferenceChange(GridOriginPreferenceKey.self) { origin in
                            gridOriginInGlobal = origin
                        }

                    // 拖拽预览叠加层
                    if isDragging && dragHeadRow >= 0 && dragHeadCol >= 0 {
                        dragPreviewOverlay(board: board)
                    }
                }
            }

            if showPlacementError {
                Text("Cannot place airplane here")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // 飞机图标和控制按钮
            HStack(spacing: 20) {
                // 可拖拽的飞机图标
                AirplaneIconView(direction: selectedDirection, size: 80)
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

                VStack(spacing: 12) {
                    Button(action: rotateDirection) {
                        Label("Rotate", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.bordered)

                    HStack(spacing: 12) {
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
                }
            }
            .padding(.top, 8)

            // 开始战斗按钮
            if viewModel.isDeploymentComplete() {
                Button("Start Battle") {
                    viewModel.confirmDeployment()
                }
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 8)
            }

            Text("Drag airplane to board or tap cell to place")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
    }

    // 拖拽预览叠加层
    @ViewBuilder
    private func dragPreviewOverlay(board: BoardManager) -> some View {
        let cells = Airplane.calculateCells(headRow: dragHeadRow, headCol: dragHeadCol, direction: selectedDirection)
        let isValid = isPlacementValid(board: board, cells: cells)

        // 使用 Canvas 或简单的 ForEach
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
        // 检查数量限制
        if board.airplanes.count >= board.airplaneCount {
            return false
        }

        for cell in cells {
            // 检查边界
            if cell.row < 0 || cell.row >= board.size || cell.col < 0 || cell.col >= board.size {
                return false
            }
            // 检查重叠
            if board.hasAirplaneAt(row: cell.row, col: cell.col) {
                return false
            }
        }
        return true
    }

    @ViewBuilder
    private func boardGrid(board: BoardManager) -> some View {
        VStack(spacing: 0) {
            // 列标签
            HStack(spacing: 0) {
                Color.clear.frame(width: labelOffsetX, height: labelOffsetY)
                ForEach(0..<board.size, id: \.self) { col in
                    Text(CoordinateSystem.indexToLetter(col))
                        .font(.system(size: min(cellSize * 0.4, 10)))
                        .foregroundColor(.gray)
                        .frame(width: cellSize, height: labelOffsetY)
                }
            }

            // 行
            ForEach(0..<board.size, id: \.self) { row in
                HStack(spacing: 0) {
                    // 行标签
                    Text("\(row + 1)")
                        .font(.system(size: min(cellSize * 0.4, 10)))
                        .foregroundColor(.gray)
                        .frame(width: labelOffsetX, height: cellSize)

                    // 格子
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
        // 计算相对于棋盘格子区域的位置
        let relativeX = globalLocation.x - gridOriginInGlobal.x - labelOffsetX
        let relativeY = globalLocation.y - gridOriginInGlobal.y - labelOffsetY

        // 转换为格子坐标
        let col = Int(relativeX / cellSize)
        let row = Int(relativeY / cellSize)

        dragHeadRow = row
        dragHeadCol = col

        print("[Drag] global: \(globalLocation), gridOrigin: \(gridOriginInGlobal), row: \(row), col: \(col)")
    }

    private func placeDraggedAirplane() {
        guard let board = viewModel.playerBoard else { return }

        let row = dragHeadRow
        let col = dragHeadCol

        // 边界检查
        guard row >= 0 && row < board.size && col >= 0 && col < board.size else {
            return
        }

        // 尝试放置
        let success = viewModel.addAirplane(headRow: row, headCol: col, direction: selectedDirection)

        if !success {
            withAnimation {
                showPlacementError = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showPlacementError = false
                }
            }
        }
    }

    private func handleCellTap(board: BoardManager, row: Int, col: Int) {
        // 如果有飞机则删除
        if let airplane = board.getAirplaneAt(row: row, col: col) {
            viewModel.removeAirplane(id: airplane.id)
            return
        }

        // 否则尝试放置
        let success = viewModel.addAirplane(headRow: row, headCol: col, direction: selectedDirection)
        if !success {
            withAnimation {
                showPlacementError = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showPlacementError = false
                }
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

// PreferenceKey 用于获取棋盘的全局位置
struct GridOriginPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}
