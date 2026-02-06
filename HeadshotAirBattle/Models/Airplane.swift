import Foundation

/// Cell type within an airplane
enum AirplaneCellType: String {
    case head, body, wing, tail
}

/// A single cell position with type information
struct AirplaneCell: Equatable {
    let row: Int
    let col: Int
    let type: AirplaneCellType
}

/// Represents a single airplane with 10 unique cells
class Airplane: Identifiable {
    let id: Int
    let headRow: Int
    let headCol: Int
    let direction: GameConstants.Direction
    let cells: [AirplaneCell]
    var hits: Set<String> = []
    var isDestroyed: Bool = false

    init(headRow: Int, headCol: Int, direction: GameConstants.Direction, id: Int) {
        self.id = id
        self.headRow = headRow
        self.headCol = headCol
        self.direction = direction
        self.cells = Airplane.calculateCells(headRow: headRow, headCol: headCol, direction: direction)
    }

    // MARK: - Cell Calculation

    /// Calculate all cell positions based on head position and direction
    static func calculateCells(headRow: Int, headCol: Int, direction: GameConstants.Direction) -> [AirplaneCell] {
        var cells: [AirplaneCell] = []
        guard let rotation = GameConstants.rotationMatrices[direction] else { return cells }

        // Add head
        cells.append(AirplaneCell(row: headRow, col: headCol, type: .head))

        // Transform relative coordinates based on direction
        func transform(_ relRow: Int, _ relCol: Int) -> (row: Int, col: Int) {
            var r = relRow, c = relCol
            if rotation.swap {
                let temp = r
                r = c
                c = temp
            }
            return (headRow + r * rotation.rowMult, headCol + c * rotation.colMult)
        }

        // Add body cells (3 cells)
        for pos in GameConstants.AirplaneStructure.body {
            let t = transform(pos.row, pos.col)
            cells.append(AirplaneCell(row: t.row, col: t.col, type: .body))
        }

        // Add wing cells (5 cells, center overlaps with body)
        for pos in GameConstants.AirplaneStructure.wings {
            let t = transform(pos.row, pos.col)
            let exists = cells.contains { $0.row == t.row && $0.col == t.col }
            if !exists {
                cells.append(AirplaneCell(row: t.row, col: t.col, type: .wing))
            }
        }

        // Add tail cells (3 cells, center overlaps with body)
        for pos in GameConstants.AirplaneStructure.tail {
            let t = transform(pos.row, pos.col)
            let exists = cells.contains { $0.row == t.row && $0.col == t.col }
            if !exists {
                cells.append(AirplaneCell(row: t.row, col: t.col, type: .tail))
            }
        }

        return cells
    }

    // MARK: - Validation

    /// Check if airplane placement is valid (within bounds and no overlaps)
    func isValidPlacement(boardSize: Int, existingAirplanes: [Airplane] = []) -> (valid: Bool, reason: String) {
        // Check bounds
        for cell in cells {
            if cell.row < 0 || cell.row >= boardSize || cell.col < 0 || cell.col >= boardSize {
                return (false, "Airplane extends outside board boundaries")
            }
        }

        // Check overlaps
        for existing in existingAirplanes {
            if existing.id == self.id { continue }
            for myCell in cells {
                for theirCell in existing.cells {
                    if myCell.row == theirCell.row && myCell.col == theirCell.col {
                        return (false, "Airplane overlaps with another airplane")
                    }
                }
            }
        }

        return (true, "")
    }

    // MARK: - Hit Detection

    /// Process an attack on this airplane
    func checkHit(row: Int, col: Int) -> (result: GameConstants.AttackResult, wasHead: Bool, cellType: AirplaneCellType?) {
        // Find hit cell
        guard let hitCell = cells.first(where: { $0.row == row && $0.col == col }) else {
            return (.miss, false, nil)
        }

        let cellKey = "\(row),\(col)"

        // Already hit this specific cell
        if hits.contains(cellKey) {
            return (.alreadyAttacked, hitCell.type == .head, hitCell.type)
        }

        // Record hit
        hits.insert(cellKey)

        // If airplane is already destroyed (e.g., head was hit earlier),
        // hitting other cells should still show as hit, not miss
        if isDestroyed {
            // This cell belongs to a destroyed airplane, show it as hit
            return (.hit, hitCell.type == .head, hitCell.type)
        }

        // Head shot = instant kill
        if hitCell.type == .head {
            isDestroyed = true
            return (.kill, true, .head)
        }

        // All cells hit = destroyed
        if hits.count == cells.count {
            isDestroyed = true
            return (.kill, false, hitCell.type)
        }

        return (.hit, false, hitCell.type)
    }

    // MARK: - Query

    func hasCell(row: Int, col: Int) -> Bool {
        return cells.contains { $0.row == row && $0.col == col }
    }

    func getCellType(row: Int, col: Int) -> AirplaneCellType? {
        return cells.first { $0.row == row && $0.col == col }?.type
    }

    func isCellHit(row: Int, col: Int) -> Bool {
        return hits.contains("\(row),\(col)")
    }

    // MARK: - Serialization

    func toData() -> AirplaneData {
        return AirplaneData(
            id: id,
            headRow: headRow,
            headCol: headCol,
            direction: direction.rawValue,
            hits: Array(hits),
            isDestroyed: isDestroyed
        )
    }

    static func fromData(_ data: AirplaneData) -> Airplane {
        guard let dir = GameConstants.Direction(rawValue: data.direction) else {
            fatalError("Invalid direction: \(data.direction)")
        }
        let airplane = Airplane(headRow: data.headRow, headCol: data.headCol, direction: dir, id: data.id)
        airplane.hits = Set(data.hits ?? [])
        airplane.isDestroyed = data.isDestroyed ?? false
        return airplane
    }

    // MARK: - Random Placement

    static func createRandom(boardSize: Int, existingAirplanes: [Airplane], id: Int, maxAttempts: Int = 100) -> Airplane? {
        let directions = GameConstants.Direction.allCases

        for _ in 0..<maxAttempts {
            let headRow = Int.random(in: 0..<boardSize)
            let headCol = Int.random(in: 0..<boardSize)
            let direction = directions.randomElement()!

            let airplane = Airplane(headRow: headRow, headCol: headCol, direction: direction, id: id)
            let validation = airplane.isValidPlacement(boardSize: boardSize, existingAirplanes: existingAirplanes)

            if validation.valid {
                return airplane
            }
        }

        return nil
    }
}
