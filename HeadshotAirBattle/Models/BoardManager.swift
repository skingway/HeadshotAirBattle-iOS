import Foundation

/// Manages the game board state, airplane collection, and attack processing
class BoardManager {
    let size: Int
    let airplaneCount: Int
    var airplanes: [Airplane] = []
    var attackHistory: [AttackRecord] = []
    var attackedCells: Set<String> = []

    init(size: Int, airplaneCount: Int) {
        self.size = size
        self.airplaneCount = airplaneCount
    }

    // MARK: - Airplane Management

    func addAirplane(_ airplane: Airplane) -> (success: Bool, reason: String) {
        if airplanes.count >= airplaneCount {
            return (false, "Maximum number of airplanes reached")
        }

        let validation = airplane.isValidPlacement(boardSize: size, existingAirplanes: airplanes)
        if !validation.valid {
            return (false, validation.reason)
        }

        airplanes.append(airplane)
        return (true, "")
    }

    func removeAirplane(id: Int) -> Bool {
        if let index = airplanes.firstIndex(where: { $0.id == id }) {
            airplanes.remove(at: index)
            return true
        }
        return false
    }

    func clearAirplanes() {
        airplanes.removeAll()
    }

    // MARK: - Attack Processing

    func processAttack(row: Int, col: Int) -> (result: GameConstants.AttackResult, airplaneId: Int?, cellType: AirplaneCellType?, wasHead: Bool) {
        // Bounds check
        if row < 0 || row >= size || col < 0 || col >= size {
            return (.invalid, nil, nil, false)
        }

        // Already attacked
        let cellKey = "\(row),\(col)"
        if attackedCells.contains(cellKey) {
            return (.alreadyAttacked, nil, nil, false)
        }

        // Mark as attacked
        attackedCells.insert(cellKey)

        // Check each airplane
        for airplane in airplanes {
            let hitResult = airplane.checkHit(row: row, col: col)

            // Skip already-attacked results from destroyed airplanes
            if hitResult.result == .alreadyAttacked {
                continue
            }

            if hitResult.result != .miss {
                let record = AttackRecord(
                    row: row,
                    col: col,
                    coordinate: CoordinateSystem.positionToCoordinate(row: row, col: col),
                    result: hitResult.result.rawValue,
                    airplaneId: airplane.id,
                    cellType: hitResult.cellType?.rawValue,
                    wasHead: hitResult.wasHead,
                    timestamp: Date().millisecondsSince1970
                )
                attackHistory.append(record)

                return (hitResult.result, airplane.id, hitResult.cellType, hitResult.wasHead)
            }
        }

        // Miss
        let record = AttackRecord(
            row: row,
            col: col,
            coordinate: CoordinateSystem.positionToCoordinate(row: row, col: col),
            result: GameConstants.AttackResult.miss.rawValue,
            airplaneId: nil,
            cellType: nil,
            wasHead: false,
            timestamp: Date().millisecondsSince1970
        )
        attackHistory.append(record)

        return (.miss, nil, nil, false)
    }

    // MARK: - State Queries

    func areAllAirplanesDestroyed() -> Bool {
        return !airplanes.isEmpty && airplanes.allSatisfy { $0.isDestroyed }
    }

    func getRemainingAirplaneCount() -> Int {
        return airplanes.filter { !$0.isDestroyed }.count
    }

    func hasAirplaneAt(row: Int, col: Int) -> Bool {
        return airplanes.contains { $0.hasCell(row: row, col: col) }
    }

    func getAirplaneAt(row: Int, col: Int) -> Airplane? {
        return airplanes.first { $0.hasCell(row: row, col: col) }
    }

    func isCellAttacked(row: Int, col: Int) -> Bool {
        return attackedCells.contains("\(row),\(col)")
    }

    func isDeploymentComplete() -> Bool {
        return airplanes.count == airplaneCount
    }

    // MARK: - Cell State for Rendering

    func getCellState(row: Int, col: Int, revealAirplanes: Bool = false) -> GameConstants.CellState {
        let cellKey = "\(row),\(col)"
        let isAttacked = attackedCells.contains(cellKey)
        let airplane = getAirplaneAt(row: row, col: col)

        if isAttacked {
            if let airplane = airplane {
                if airplane.isCellHit(row: row, col: col) {
                    if airplane.isDestroyed {
                        return .killed  // 飞机被摧毁后，所有已击中格子都显示 killed
                    }
                    return .hit
                }
            }
            return .miss
        }

        if revealAirplanes && airplane != nil {
            return .airplane
        }

        return .empty
    }

    // MARK: - Statistics

    func getStatistics() -> GameStats {
        var stats = GameStats()
        for record in attackHistory {
            if record.result == GameConstants.AttackResult.hit.rawValue ||
               record.result == GameConstants.AttackResult.kill.rawValue {
                stats.hits += 1
                if record.result == GameConstants.AttackResult.kill.rawValue {
                    stats.kills += 1
                }
            } else if record.result == GameConstants.AttackResult.miss.rawValue {
                stats.misses += 1
            }
        }
        return stats
    }

    // MARK: - Random Placement

    func placeAirplanesRandomly() -> Bool {
        let maxRetries = 10

        for _ in 0..<maxRetries {
            clearAirplanes()
            var success = true

            for i in 0..<airplaneCount {
                let maxAttempts = max(100, airplaneCount * 100)
                if let airplane = Airplane.createRandom(
                    boardSize: size, existingAirplanes: airplanes, id: i, maxAttempts: maxAttempts
                ) {
                    airplanes.append(airplane)
                } else {
                    success = false
                    break
                }
            }

            if success { return true }
        }

        clearAirplanes()
        return false
    }

    // MARK: - External Attack Recording (for online multiplayer)

    func recordExternalAttack(row: Int, col: Int, result: String, airplaneId: Int? = nil) {
        let cellKey = "\(row),\(col)"
        attackedCells.insert(cellKey)

        let record = AttackRecord(
            row: row,
            col: col,
            coordinate: CoordinateSystem.positionToCoordinate(row: row, col: col),
            result: result,
            airplaneId: airplaneId,
            cellType: nil,
            wasHead: result == GameConstants.AttackResult.kill.rawValue,
            timestamp: Date().millisecondsSince1970
        )
        attackHistory.append(record)
    }

    // MARK: - Serialization

    func toData() -> BoardData {
        return BoardData(
            size: size,
            airplaneCount: airplaneCount,
            airplanes: airplanes.map { $0.toData() },
            attackHistory: attackHistory,
            attackedCells: Array(attackedCells)
        )
    }

    static func fromData(_ data: BoardData) -> BoardManager {
        let board = BoardManager(size: data.size, airplaneCount: data.airplaneCount)
        board.airplanes = data.airplanes.map { Airplane.fromData($0) }
        board.attackHistory = data.attackHistory
        board.attackedCells = Set(data.attackedCells)
        return board
    }

    // MARK: - Reset

    func reset() {
        attackHistory.removeAll()
        attackedCells.removeAll()
        for airplane in airplanes {
            airplane.hits.removeAll()
            airplane.isDestroyed = false
        }
    }

    func getAllAirplaneCells() -> [(row: Int, col: Int, airplaneId: Int, type: AirplaneCellType)] {
        var result: [(row: Int, col: Int, airplaneId: Int, type: AirplaneCellType)] = []
        for airplane in airplanes {
            for cell in airplane.cells {
                result.append((cell.row, cell.col, airplane.id, cell.type))
            }
        }
        return result
    }
}
