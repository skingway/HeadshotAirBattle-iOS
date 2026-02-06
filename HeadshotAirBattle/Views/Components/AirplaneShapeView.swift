import SwiftUI

/// Renders a realistic airplane shape preview with the given direction
struct AirplaneShapeView: View {
    let direction: GameConstants.Direction
    let cellSize: CGFloat
    var showDetailedShape: Bool = true

    private var skinColor: Color {
        Color(hex: SkinDefinitions.currentSkinColor())
    }

    // 计算机头在预览视图中的偏移量（用于拖拽定位）
    var headOffset: CGSize {
        // 飞机占用的格子范围
        let cells = Airplane.calculateCells(headRow: 3, headCol: 3, direction: direction)
        let minRow = cells.map(\.row).min() ?? 0
        let minCol = cells.map(\.col).min() ?? 0

        // 机头相对于左上角的偏移
        let headRow = 3 - minRow
        let headCol = 3 - minCol

        return CGSize(
            width: CGFloat(headCol) * cellSize + cellSize / 2,
            height: CGFloat(headRow) * cellSize + cellSize / 2
        )
    }

    var body: some View {
        let cells = Airplane.calculateCells(headRow: 3, headCol: 3, direction: direction)

        let minRow = cells.map(\.row).min() ?? 0
        let minCol = cells.map(\.col).min() ?? 0
        let maxRow = cells.map(\.row).max() ?? 0
        let maxCol = cells.map(\.col).max() ?? 0

        let rows = maxRow - minRow + 1
        let cols = maxCol - minCol + 1

        // 使用 Path 绘制真实飞机形状
        ZStack {
            // 飞机整体形状
            FighterJetShape(direction: direction, cellSize: cellSize, rows: rows, cols: cols)
                .fill(
                    LinearGradient(
                        colors: [skinColor, skinColor.opacity(0.7)],
                        startPoint: gradientStart,
                        endPoint: gradientEnd
                    )
                )

            // 飞机轮廓
            FighterJetShape(direction: direction, cellSize: cellSize, rows: rows, cols: cols)
                .stroke(skinColor.opacity(0.8), lineWidth: 1)

            // 驾驶舱
            CockpitShape(direction: direction, cellSize: cellSize, rows: rows, cols: cols)
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.8), Color.blue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // 机翼装饰线
            WingStripes(direction: direction, cellSize: cellSize, rows: rows, cols: cols)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        }
        .frame(width: CGFloat(cols) * cellSize, height: CGFloat(rows) * cellSize)
    }

    private var gradientStart: UnitPoint {
        switch direction {
        case .up: return .top
        case .down: return .bottom
        case .left: return .leading
        case .right: return .trailing
        }
    }

    private var gradientEnd: UnitPoint {
        switch direction {
        case .up: return .bottom
        case .down: return .top
        case .left: return .trailing
        case .right: return .leading
        }
    }
}

/// 战斗机形状
struct FighterJetShape: Shape {
    let direction: GameConstants.Direction
    let cellSize: CGFloat
    let rows: Int
    let cols: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = CGFloat(cols) * cellSize
        let h = CGFloat(rows) * cellSize

        switch direction {
        case .up:
            // 机头（尖锐）
            path.move(to: CGPoint(x: w / 2, y: 0))
            // 左侧机身
            path.addLine(to: CGPoint(x: w * 0.35, y: cellSize * 0.8))
            // 左机翼
            path.addLine(to: CGPoint(x: 0, y: cellSize * 2))
            path.addLine(to: CGPoint(x: 0, y: cellSize * 2.3))
            path.addLine(to: CGPoint(x: w * 0.35, y: cellSize * 1.8))
            // 左侧机身继续
            path.addLine(to: CGPoint(x: w * 0.35, y: cellSize * 3.2))
            // 左尾翼
            path.addLine(to: CGPoint(x: 0, y: cellSize * 3.8))
            path.addLine(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: w * 0.35, y: cellSize * 3.8))
            // 尾部
            path.addLine(to: CGPoint(x: w * 0.5, y: h))
            // 右侧对称
            path.addLine(to: CGPoint(x: w * 0.65, y: cellSize * 3.8))
            path.addLine(to: CGPoint(x: w, y: h))
            path.addLine(to: CGPoint(x: w, y: cellSize * 3.8))
            path.addLine(to: CGPoint(x: w * 0.65, y: cellSize * 3.2))
            path.addLine(to: CGPoint(x: w * 0.65, y: cellSize * 1.8))
            path.addLine(to: CGPoint(x: w, y: cellSize * 2.3))
            path.addLine(to: CGPoint(x: w, y: cellSize * 2))
            path.addLine(to: CGPoint(x: w * 0.65, y: cellSize * 0.8))
            path.closeSubpath()

        case .down:
            path.move(to: CGPoint(x: w / 2, y: h))
            path.addLine(to: CGPoint(x: w * 0.35, y: h - cellSize * 0.8))
            path.addLine(to: CGPoint(x: 0, y: h - cellSize * 2))
            path.addLine(to: CGPoint(x: 0, y: h - cellSize * 2.3))
            path.addLine(to: CGPoint(x: w * 0.35, y: h - cellSize * 1.8))
            path.addLine(to: CGPoint(x: w * 0.35, y: h - cellSize * 3.2))
            path.addLine(to: CGPoint(x: 0, y: h - cellSize * 3.8))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: w * 0.35, y: h - cellSize * 3.8))
            path.addLine(to: CGPoint(x: w * 0.5, y: 0))
            path.addLine(to: CGPoint(x: w * 0.65, y: h - cellSize * 3.8))
            path.addLine(to: CGPoint(x: w, y: 0))
            path.addLine(to: CGPoint(x: w, y: h - cellSize * 3.8))
            path.addLine(to: CGPoint(x: w * 0.65, y: h - cellSize * 3.2))
            path.addLine(to: CGPoint(x: w * 0.65, y: h - cellSize * 1.8))
            path.addLine(to: CGPoint(x: w, y: h - cellSize * 2.3))
            path.addLine(to: CGPoint(x: w, y: h - cellSize * 2))
            path.addLine(to: CGPoint(x: w * 0.65, y: h - cellSize * 0.8))
            path.closeSubpath()

        case .left:
            path.move(to: CGPoint(x: 0, y: h / 2))
            path.addLine(to: CGPoint(x: cellSize * 0.8, y: h * 0.35))
            path.addLine(to: CGPoint(x: cellSize * 2, y: 0))
            path.addLine(to: CGPoint(x: cellSize * 2.3, y: 0))
            path.addLine(to: CGPoint(x: cellSize * 1.8, y: h * 0.35))
            path.addLine(to: CGPoint(x: cellSize * 3.2, y: h * 0.35))
            path.addLine(to: CGPoint(x: cellSize * 3.8, y: 0))
            path.addLine(to: CGPoint(x: w, y: 0))
            path.addLine(to: CGPoint(x: cellSize * 3.8, y: h * 0.35))
            path.addLine(to: CGPoint(x: w, y: h * 0.5))
            path.addLine(to: CGPoint(x: cellSize * 3.8, y: h * 0.65))
            path.addLine(to: CGPoint(x: w, y: h))
            path.addLine(to: CGPoint(x: cellSize * 3.8, y: h))
            path.addLine(to: CGPoint(x: cellSize * 3.2, y: h * 0.65))
            path.addLine(to: CGPoint(x: cellSize * 1.8, y: h * 0.65))
            path.addLine(to: CGPoint(x: cellSize * 2.3, y: h))
            path.addLine(to: CGPoint(x: cellSize * 2, y: h))
            path.addLine(to: CGPoint(x: cellSize * 0.8, y: h * 0.65))
            path.closeSubpath()

        case .right:
            path.move(to: CGPoint(x: w, y: h / 2))
            path.addLine(to: CGPoint(x: w - cellSize * 0.8, y: h * 0.35))
            path.addLine(to: CGPoint(x: w - cellSize * 2, y: 0))
            path.addLine(to: CGPoint(x: w - cellSize * 2.3, y: 0))
            path.addLine(to: CGPoint(x: w - cellSize * 1.8, y: h * 0.35))
            path.addLine(to: CGPoint(x: w - cellSize * 3.2, y: h * 0.35))
            path.addLine(to: CGPoint(x: w - cellSize * 3.8, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: w - cellSize * 3.8, y: h * 0.35))
            path.addLine(to: CGPoint(x: 0, y: h * 0.5))
            path.addLine(to: CGPoint(x: w - cellSize * 3.8, y: h * 0.65))
            path.addLine(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: w - cellSize * 3.8, y: h))
            path.addLine(to: CGPoint(x: w - cellSize * 3.2, y: h * 0.65))
            path.addLine(to: CGPoint(x: w - cellSize * 1.8, y: h * 0.65))
            path.addLine(to: CGPoint(x: w - cellSize * 2.3, y: h))
            path.addLine(to: CGPoint(x: w - cellSize * 2, y: h))
            path.addLine(to: CGPoint(x: w - cellSize * 0.8, y: h * 0.65))
            path.closeSubpath()
        }

        return path
    }
}

/// 驾驶舱形状
struct CockpitShape: Shape {
    let direction: GameConstants.Direction
    let cellSize: CGFloat
    let rows: Int
    let cols: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = CGFloat(cols) * cellSize
        let h = CGFloat(rows) * cellSize

        switch direction {
        case .up:
            let cx = w / 2
            let cy = cellSize * 0.6
            path.addEllipse(in: CGRect(x: cx - cellSize * 0.25, y: cy - cellSize * 0.15,
                                       width: cellSize * 0.5, height: cellSize * 0.35))
        case .down:
            let cx = w / 2
            let cy = h - cellSize * 0.6
            path.addEllipse(in: CGRect(x: cx - cellSize * 0.25, y: cy - cellSize * 0.2,
                                       width: cellSize * 0.5, height: cellSize * 0.35))
        case .left:
            let cx = cellSize * 0.6
            let cy = h / 2
            path.addEllipse(in: CGRect(x: cx - cellSize * 0.15, y: cy - cellSize * 0.25,
                                       width: cellSize * 0.35, height: cellSize * 0.5))
        case .right:
            let cx = w - cellSize * 0.6
            let cy = h / 2
            path.addEllipse(in: CGRect(x: cx - cellSize * 0.2, y: cy - cellSize * 0.25,
                                       width: cellSize * 0.35, height: cellSize * 0.5))
        }

        return path
    }
}

/// 机翼装饰线
struct WingStripes: Shape {
    let direction: GameConstants.Direction
    let cellSize: CGFloat
    let rows: Int
    let cols: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = CGFloat(cols) * cellSize
        let h = CGFloat(rows) * cellSize

        switch direction {
        case .up:
            // 左机翼线
            path.move(to: CGPoint(x: w * 0.1, y: cellSize * 2.1))
            path.addLine(to: CGPoint(x: w * 0.35, y: cellSize * 1.5))
            // 右机翼线
            path.move(to: CGPoint(x: w * 0.9, y: cellSize * 2.1))
            path.addLine(to: CGPoint(x: w * 0.65, y: cellSize * 1.5))
        case .down:
            path.move(to: CGPoint(x: w * 0.1, y: h - cellSize * 2.1))
            path.addLine(to: CGPoint(x: w * 0.35, y: h - cellSize * 1.5))
            path.move(to: CGPoint(x: w * 0.9, y: h - cellSize * 2.1))
            path.addLine(to: CGPoint(x: w * 0.65, y: h - cellSize * 1.5))
        case .left:
            path.move(to: CGPoint(x: cellSize * 2.1, y: h * 0.1))
            path.addLine(to: CGPoint(x: cellSize * 1.5, y: h * 0.35))
            path.move(to: CGPoint(x: cellSize * 2.1, y: h * 0.9))
            path.addLine(to: CGPoint(x: cellSize * 1.5, y: h * 0.65))
        case .right:
            path.move(to: CGPoint(x: w - cellSize * 2.1, y: h * 0.1))
            path.addLine(to: CGPoint(x: w - cellSize * 1.5, y: h * 0.35))
            path.move(to: CGPoint(x: w - cellSize * 2.1, y: h * 0.9))
            path.addLine(to: CGPoint(x: w - cellSize * 1.5, y: h * 0.65))
        }

        return path
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
            // 驾驶舱高光
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: cellSize * 0.3, height: cellSize * 0.3)
                .offset(x: -cellSize * 0.1, y: -cellSize * 0.1)
        case .body:
            // 机身条纹
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: cellSize * 0.5, height: cellSize * 0.06)
        case .wing:
            // 机翼标记
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
