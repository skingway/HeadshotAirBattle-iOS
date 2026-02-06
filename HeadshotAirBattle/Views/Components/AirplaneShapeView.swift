import SwiftUI

/// Renders an airplane image with the given direction
struct AirplaneShapeView: View {
    let direction: GameConstants.Direction
    let cellSize: CGFloat
    var showDetailedShape: Bool = true

    // 飞机占用的格子范围（用于计算尺寸）
    private var airplaneSize: (rows: Int, cols: Int) {
        let cells = Airplane.calculateCells(headRow: 3, headCol: 3, direction: direction)
        let minRow = cells.map(\.row).min() ?? 0
        let minCol = cells.map(\.col).min() ?? 0
        let maxRow = cells.map(\.row).max() ?? 0
        let maxCol = cells.map(\.col).max() ?? 0
        return (maxRow - minRow + 1, maxCol - minCol + 1)
    }

    // 计算机头在预览视图中的偏移量（用于拖拽定位）
    var headOffset: CGSize {
        let cells = Airplane.calculateCells(headRow: 3, headCol: 3, direction: direction)
        let minRow = cells.map(\.row).min() ?? 0
        let minCol = cells.map(\.col).min() ?? 0
        let headRow = 3 - minRow
        let headCol = 3 - minCol

        return CGSize(
            width: CGFloat(headCol) * cellSize + cellSize / 2,
            height: CGFloat(headRow) * cellSize + cellSize / 2
        )
    }

    private var rotationAngle: Angle {
        switch direction {
        case .up: return .degrees(0)
        case .right: return .degrees(90)
        case .down: return .degrees(180)
        case .left: return .degrees(270)
        }
    }

    var body: some View {
        let size = airplaneSize
        let width = CGFloat(size.cols) * cellSize
        let height = CGFloat(size.rows) * cellSize

        Image("airplane")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: min(width, height), height: max(width, height))
            .rotationEffect(rotationAngle)
            .frame(width: width, height: height)
    }
}

/// 小尺寸飞机图标（用于方向选择等）
struct AirplaneIconView: View {
    let direction: GameConstants.Direction
    var size: CGFloat = 60

    private var rotationAngle: Angle {
        switch direction {
        case .up: return .degrees(0)
        case .right: return .degrees(90)
        case .down: return .degrees(180)
        case .left: return .degrees(270)
        }
    }

    var body: some View {
        Image("airplane")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .rotationEffect(rotationAngle)
    }
}

/// 单个飞机格子视图 - 用于棋盘上显示已部署的飞机
struct AirplaneCellView: View {
    let type: AirplaneCellType
    let cellSize: CGFloat
    var showDetailed: Bool = true

    private var skinColor: Color {
        Color(hex: SkinDefinitions.currentSkinColor())
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(cellGradient)
                .frame(width: cellSize, height: cellSize)

            if showDetailed {
                cellDetail
            }
        }
        .frame(width: cellSize, height: cellSize)
    }

    private var cornerRadius: CGFloat {
        switch type {
        case .head:
            return cellSize / 2
        case .body:
            return cellSize * 0.2
        case .wing:
            return cellSize * 0.15
        case .tail:
            return cellSize * 0.1
        }
    }

    private var cellGradient: LinearGradient {
        switch type {
        case .head:
            return LinearGradient(
                colors: [Color.cyan.opacity(0.8), Color.blue.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .body:
            return LinearGradient(
                colors: [skinColor, skinColor.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .wing:
            return LinearGradient(
                colors: [skinColor.opacity(0.9), skinColor.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .tail:
            return LinearGradient(
                colors: [skinColor.opacity(0.7), skinColor.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var cellDetail: some View {
        switch type {
        case .head:
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: cellSize * 0.3, height: cellSize * 0.3)
                .offset(x: -cellSize * 0.1, y: -cellSize * 0.1)
        case .body:
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: cellSize * 0.5, height: cellSize * 0.06)
        case .wing:
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: cellSize * 0.6, height: cellSize * 0.04)
        case .tail:
            EmptyView()
        }
    }
}

/// 用于部署界面显示飞机的格子
struct DeployedAirplaneCellView: View {
    let airplane: Airplane?
    let row: Int
    let col: Int
    let cellSize: CGFloat
    let themeColors: ThemeColors

    var body: some View {
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
                .frame(width: cellSize, height: cellSize)
        }
    }
}
