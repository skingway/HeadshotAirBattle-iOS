import SwiftUI

/// Renders an airplane shape preview with the given direction
struct AirplaneShapeView: View {
    let direction: GameConstants.Direction
    let cellSize: CGFloat
    var showDetailedShape: Bool = true

    var body: some View {
        let cells = Airplane.calculateCells(headRow: 3, headCol: 3, direction: direction)

        let minRow = cells.map(\.row).min() ?? 0
        let minCol = cells.map(\.col).min() ?? 0
        let maxRow = cells.map(\.row).max() ?? 0
        let maxCol = cells.map(\.col).max() ?? 0

        let rows = maxRow - minRow + 1
        let cols = maxCol - minCol + 1

        ZStack {
            // 背景格子
            VStack(spacing: 1) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: 1) {
                        ForEach(0..<cols, id: \.self) { c in
                            let row = r + minRow
                            let col = c + minCol
                            let cell = cells.first { $0.row == row && $0.col == col }

                            if let cell = cell {
                                AirplaneCellView(type: cell.type, cellSize: cellSize, showDetailed: showDetailedShape)
                            } else {
                                Color.clear
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
        }
    }
}

/// 单个飞机格子视图 - 根据类型绘制不同样式
struct AirplaneCellView: View {
    let type: AirplaneCellType
    let cellSize: CGFloat
    var showDetailed: Bool = true

    private var skinColor: Color {
        Color(hex: SkinDefinitions.currentSkinColor())
    }

    var body: some View {
        ZStack {
            // 基础形状
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(cellGradient)
                .frame(width: cellSize, height: cellSize)

            // 细节装饰
            if showDetailed {
                cellDetail
            }
        }
        .frame(width: cellSize, height: cellSize)
    }

    private var cornerRadius: CGFloat {
        switch type {
        case .head:
            return cellSize / 2  // 圆形
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
            // 机头 - 白色渐变，像驾驶舱玻璃
            return LinearGradient(
                colors: [.white, Color.white.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .body:
            // 机身 - 主颜色渐变
            return LinearGradient(
                colors: [skinColor, skinColor.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .wing:
            // 机翼 - 略浅的颜色
            return LinearGradient(
                colors: [skinColor.opacity(0.9), skinColor.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .tail:
            // 尾翼 - 更浅的颜色
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
            // 驾驶舱窗户效果
            Circle()
                .fill(Color.cyan.opacity(0.5))
                .frame(width: cellSize * 0.5, height: cellSize * 0.5)
                .offset(x: -cellSize * 0.1, y: -cellSize * 0.1)
        case .body:
            // 机身条纹
            VStack(spacing: cellSize * 0.15) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: cellSize * 0.6, height: cellSize * 0.08)
            }
        case .wing:
            // 机翼标记
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: cellSize * 0.7, height: cellSize * 0.05)
        case .tail:
            // 尾翼纹理
            EmptyView()
        }
    }
}

// 用于部署界面显示飞机的格子（显示为飞机样式而非简单方块）
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
                    // 机头标记
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
