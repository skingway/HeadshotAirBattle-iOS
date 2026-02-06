import SwiftUI

/// Board view for airplane deployment phase - tap to place, buttons to rotate/random/clear
struct DeploymentBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedDirection: GameConstants.Direction = .up
    @State private var isDragging = false
    @State private var dragPosition: CGPoint = .zero
    @State private var boardOrigin: CGPoint = .zero
    @State private var showPlacementError = false
    private let themeColors = SkinDefinitions.currentThemeColors()

    private var cellSize: CGFloat {
        let boardSize = viewModel.playerBoard?.size ?? 10
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 60
        let size = availableWidth / CGFloat(boardSize)
        return min(max(size, GameConstants.GridDisplay.minCellSize), GameConstants.GridDisplay.maxCellSize)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 12) {
                    Text("Deploy Your Fleet")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("\(viewModel.deployedAirplanes.count)/\(viewModel.playerBoard?.airplaneCount ?? 3) airplanes placed")
                        .font(.caption)
                        .foregroundColor(.gray)

                    // Board
                    if let board = viewModel.playerBoard {
                        boardGrid(board: board)
                            .background(
                                GeometryReader { boardGeometry in
                                    Color.clear
                                        .onAppear {
                                            boardOrigin = boardGeometry.frame(in: .global).origin
                                        }
                                        .onChange(of: boardGeometry.frame(in: .global)) { newFrame in
                                            boardOrigin = newFrame.origin
                                        }
                                }
                            )
                    }

                    if showPlacementError {
                        Text("Cannot place airplane here")
                            .font(.caption)
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }

                    // Airplane preview - draggable
                    AirplaneShapeView(direction: selectedDirection, cellSize: 20)
                        .frame(height: 100)
                        .gesture(
                            DragGesture(coordinateSpace: .global)
                                .onChanged { value in
                                    isDragging = true
                                    dragPosition = value.location
                                }
                                .onEnded { value in
                                    handleDrop(at: value.location)
                                    isDragging = false
                                }
                        )

                    // Controls
                    HStack(spacing: 16) {
                        Button(action: rotateDirection) {
                            Label("Rotate", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.bordered)

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

                    // Confirm button
                    if viewModel.isDeploymentComplete() {
                        Button("Start Battle") {
                            viewModel.confirmDeployment()
                        }
                        .font(.headline)
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding()

                // Drag preview overlay - 机头跟随手指位置
                if isDragging {
                    let preview = AirplaneShapeView(direction: selectedDirection, cellSize: cellSize)
                    let headOffset = preview.headOffset
                    let geometryOrigin = geometry.frame(in: .global).origin

                    preview
                        .opacity(0.7)
                        .position(
                            x: dragPosition.x - geometryOrigin.x - headOffset.width + cellSize / 2,
                            y: dragPosition.y - geometryOrigin.y - headOffset.height + cellSize / 2
                        )
                        .allowsHitTesting(false)
                }
            }
        }
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

    private func handleCellTap(row: Int, col: Int) {
        guard let board = viewModel.playerBoard else { return }

        // If there's an airplane here, remove it
        if let airplane = board.getAirplaneAt(row: row, col: col) {
            viewModel.removeAirplane(id: airplane.id)
            return
        }

        // Try to place an airplane
        _ = viewModel.addAirplane(headRow: row, headCol: col, direction: selectedDirection)
    }

    private func handleDrop(at globalLocation: CGPoint) {
        guard let board = viewModel.playerBoard else { return }

        // 计算相对于棋盘的位置
        let relativeX = globalLocation.x - boardOrigin.x
        let relativeY = globalLocation.y - boardOrigin.y

        // 考虑坐标轴标签的宽度
        let gridOriginX: CGFloat = 24  // 行标签宽度
        let gridOriginY: CGFloat = 16  // 列标签高度

        // 转换为棋盘坐标
        let col = Int((relativeX - gridOriginX) / cellSize)
        let row = Int((relativeY - gridOriginY) / cellSize)

        print("[DeploymentBoardView] Drop at global: \(globalLocation), boardOrigin: \(boardOrigin)")
        print("[DeploymentBoardView] Relative: (\(relativeX), \(relativeY)) -> row: \(row), col: \(col)")

        // 边界检查
        guard row >= 0 && row < board.size && col >= 0 && col < board.size else {
            print("[DeploymentBoardView] Out of bounds")
            return
        }

        // 检查是否已有飞机，有则移除
        if let airplane = board.getAirplaneAt(row: row, col: col) {
            viewModel.removeAirplane(id: airplane.id)
            return
        }

        // 尝试放置飞机
        let success = viewModel.addAirplane(headRow: row, headCol: col, direction: selectedDirection)
        print("[DeploymentBoardView] Place airplane at (\(row), \(col)) direction: \(selectedDirection): \(success)")

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
