import SwiftUI

/// Board view for airplane deployment phase - drag airplane to board to place
struct DeploymentBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedDirection: GameConstants.Direction = .up
    @State private var isDragging = false
    @State private var dragHeadRow: Int? = nil  // 拖拽时机头所在的行
    @State private var dragHeadCol: Int? = nil  // 拖拽时机头所在的列
    @State private var showPlacementError = false
    @State private var boardOrigin: CGPoint = .zero
    private let themeColors = SkinDefinitions.currentThemeColors()

    private var cellSize: CGFloat {
        let boardSize = viewModel.playerBoard?.size ?? 10
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 60
        let size = availableWidth / CGFloat(boardSize)
        return min(max(size, GameConstants.GridDisplay.minCellSize), GameConstants.GridDisplay.maxCellSize)
    }

    // 计算拖拽预览的飞机格子
    private var dragPreviewCells: [AirplaneCell] {
        guard let row = dragHeadRow, let col = dragHeadCol else { return [] }
        return Airplane.calculateCells(headRow: row, headCol: col, direction: selectedDirection)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Deploy Your Fleet")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("\(viewModel.deployedAirplanes.count)/\(viewModel.playerBoard?.airplaneCount ?? 3) airplanes placed")
                .font(.caption)
                .foregroundColor(.gray)

            // Board with drag preview overlay
            if let board = viewModel.playerBoard {
                ZStack {
                    boardGrid(board: board)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear { boardOrigin = geo.frame(in: .global).origin }
                                    .onChange(of: geo.frame(in: .global)) { boardOrigin = $0.origin }
                            }
                        )

                    // 拖拽预览 - 直接显示在棋盘格子上
                    if isDragging && dragHeadRow != nil {
                        dragPreviewOverlay(board: board)
                    }
                }
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { value in
                            isDragging = true
                            updateDragPosition(globalLocation: value.location, board: board)
                        }
                        .onEnded { value in
                            handleDrop()
                            isDragging = false
                            dragHeadRow = nil
                            dragHeadCol = nil
                        }
                )
            }

            if showPlacementError {
                Text("Cannot place airplane here")
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }

            // Airplane icon and controls
            HStack(spacing: 20) {
                // 飞机图标（用于开始拖拽）
                VStack {
                    AirplaneIconView(direction: selectedDirection, size: 80)
                        .opacity(isDragging ? 0.3 : 1.0)
                    Text("Drag to board")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                VStack(spacing: 12) {
                    // Rotate button
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

            // Confirm button
            if viewModel.isDeploymentComplete() {
                Button("Start Battle") {
                    viewModel.confirmDeployment()
                }
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 8)
            }
        }
        .padding()
    }

    // 拖拽预览叠加层 - 显示飞机将要放置的位置
    @ViewBuilder
    private func dragPreviewOverlay(board: BoardManager) -> some View {
        let cells = dragPreviewCells
        let isValidPlacement = checkPlacementValid(board: board, cells: cells)

        ForEach(cells, id: \.row) { cell in
            if cell.row >= 0 && cell.row < board.size && cell.col >= 0 && cell.col < board.size {
                Rectangle()
                    .fill(isValidPlacement ? Color.green.opacity(0.5) : Color.red.opacity(0.5))
                    .frame(width: cellSize, height: cellSize)
                    .overlay(
                        Group {
                            if cell.type == .head {
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: cellSize * 0.6, height: cellSize * 0.6)
                            }
                        }
                    )
                    .position(cellPosition(row: cell.row, col: cell.col, board: board))
            }
        }
    }

    // 计算格子在棋盘上的位置
    private func cellPosition(row: Int, col: Int, board: BoardManager) -> CGPoint {
        let gridOriginX: CGFloat = 24  // 行标签宽度
        let gridOriginY: CGFloat = 16  // 列标签高度

        return CGPoint(
            x: gridOriginX + CGFloat(col) * cellSize + cellSize / 2,
            y: gridOriginY + CGFloat(row) * cellSize + cellSize / 2
        )
    }

    // 检查放置是否有效
    private func checkPlacementValid(board: BoardManager, cells: [AirplaneCell]) -> Bool {
        // 检查边界
        for cell in cells {
            if cell.row < 0 || cell.row >= board.size || cell.col < 0 || cell.col >= board.size {
                return false
            }
        }

        // 检查重叠
        for cell in cells {
            if board.hasAirplaneAt(row: cell.row, col: cell.col) {
                return false
            }
        }

        // 检查数量
        if board.airplanes.count >= board.airplaneCount {
            return false
        }

        return true
    }

    @ViewBuilder
    private func boardGrid(board: BoardManager) -> some View {
        VStack(spacing: 0) {
            // Column labels
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 24, height: 16)
                ForEach(0..<board.size, id: \.self) { col in
                    Text(CoordinateSystem.indexToLetter(col))
                        .font(.system(size: min(cellSize * 0.4, 10)))
                        .foregroundColor(.gray)
                        .frame(width: cellSize, height: 16)
                }
            }

            ForEach(0..<board.size, id: \.self) { row in
                HStack(spacing: 0) {
                    Text("\(row + 1)")
                        .font(.system(size: min(cellSize * 0.4, 10)))
                        .foregroundColor(.gray)
                        .frame(width: 24)

                    ForEach(0..<board.size, id: \.self) { col in
                        let airplane = board.getAirplaneAt(row: row, col: col)

                        DeployedAirplaneCellView(
                            airplane: airplane,
                            row: row,
                            col: col,
                            cellSize: cellSize,
                            themeColors: themeColors
                        )
                        .overlay(
                            Rectangle()
                                .stroke(Color(hex: themeColors.gridLine), lineWidth: 0.5)
                        )
                        .onTapGesture {
                            handleCellTap(row: row, col: col)
                        }
                    }
                }
            }
        }
    }

    private func updateDragPosition(globalLocation: CGPoint, board: BoardManager) {
        // 计算相对于棋盘的位置
        let relativeX = globalLocation.x - boardOrigin.x
        let relativeY = globalLocation.y - boardOrigin.y

        let gridOriginX: CGFloat = 24
        let gridOriginY: CGFloat = 16

        // 转换为格子坐标
        let col = Int((relativeX - gridOriginX) / cellSize)
        let row = Int((relativeY - gridOriginY) / cellSize)

        // 更新拖拽位置（即使超出边界也更新，让用户看到预览）
        dragHeadRow = row
        dragHeadCol = col
    }

    private func handleDrop() {
        guard let board = viewModel.playerBoard,
              let row = dragHeadRow,
              let col = dragHeadCol else { return }

        // 边界检查
        guard row >= 0 && row < board.size && col >= 0 && col < board.size else {
            showError()
            return
        }

        // 检查是否已有飞机，有则移除
        if let airplane = board.getAirplaneAt(row: row, col: col) {
            viewModel.removeAirplane(id: airplane.id)
            return
        }

        // 尝试放置飞机
        let success = viewModel.addAirplane(headRow: row, headCol: col, direction: selectedDirection)

        if !success {
            showError()
        }
    }

    private func handleCellTap(row: Int, col: Int) {
        guard let board = viewModel.playerBoard else { return }

        // If there's an airplane here, remove it
        if let airplane = board.getAirplaneAt(row: row, col: col) {
            viewModel.removeAirplane(id: airplane.id)
            return
        }

        // Try to place an airplane
        let success = viewModel.addAirplane(headRow: row, headCol: col, direction: selectedDirection)
        if !success {
            showError()
        }
    }

    private func showError() {
        withAnimation {
            showPlacementError = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
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
