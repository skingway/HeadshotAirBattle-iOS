import Foundation

/// Hard AI: "Lock Head" algorithm with candidate set pruning
/// Three states: SEARCH -> LOCK -> KILL
class AIStrategyHard: AIStrategy {

    enum AIState {
        case search, lock, kill
    }

    private var aiState: AIState = .search
    private var candidatePlanes: [CandidatePlane] = []

    struct CandidatePlane {
        let direction: GameConstants.Direction
        let headPos: (row: Int, col: Int)
        let cells: [AirplaneCell]
        var head: (row: Int, col: Int) { headPos }
    }

    init(boardSize: Int) {
        super.init(difficulty: .hard, boardSize: boardSize)
        initCandidatePlanes()
    }

    // MARK: - Initialization

    private func initCandidatePlanes() {
        candidatePlanes.removeAll()

        // Generate plane templates from actual Airplane class
        let templates = getPlaneTemplates()

        for headRow in 0..<boardSize {
            for headCol in 0..<boardSize {
                for template in templates {
                    let plane = buildPlane(headRow: headRow, headCol: headCol, template: template)
                    if isPlaneInsideBoard(plane) {
                        candidatePlanes.append(plane)
                    }
                }
            }
        }
    }

    private func getPlaneTemplates() -> [(direction: GameConstants.Direction, offsets: [AirplaneCell])] {
        var templates: [(direction: GameConstants.Direction, offsets: [AirplaneCell])] = []

        for direction in GameConstants.Direction.allCases {
            let tempCells = Airplane.calculateCells(headRow: 5, headCol: 5, direction: direction)
            let offsets = tempCells.map { cell in
                AirplaneCell(row: cell.row - 5, col: cell.col - 5, type: cell.type)
            }
            templates.append((direction, offsets))
        }

        return templates
    }

    private func buildPlane(headRow: Int, headCol: Int, template: (direction: GameConstants.Direction, offsets: [AirplaneCell])) -> CandidatePlane {
        let cells = template.offsets.map { offset in
            AirplaneCell(row: headRow + offset.row, col: headCol + offset.col, type: offset.type)
        }
        return CandidatePlane(direction: template.direction, headPos: (headRow, headCol), cells: cells)
    }

    private func isPlaneInsideBoard(_ plane: CandidatePlane) -> Bool {
        return plane.cells.allSatisfy {
            $0.row >= 0 && $0.row < boardSize && $0.col >= 0 && $0.col < boardSize
        }
    }

    // MARK: - Override Hard Attack

    override func getHardAttack(opponentBoard: BoardManager) -> (row: Int, col: Int)? {
        updateCandidatePlanes(opponentBoard: opponentBoard)

        let history = opponentBoard.attackHistory
        let activeHits = history.filter { $0.result == GameConstants.AttackResult.hit.rawValue }

        // Try direction probe from latest hit
        if !activeHits.isEmpty && candidatePlanes.count > 20 {
            if let probe = probeDirectionFromHit(hit: activeHits.last!, opponentBoard: opponentBoard) {
                return probe
            }
        }

        // State-based strategy
        switch aiState {
        case .search:
            return searchShot(opponentBoard: opponentBoard)
        case .lock:
            return lockShot(opponentBoard: opponentBoard)
        case .kill:
            return lockShot(opponentBoard: opponentBoard) // Same as lock but more aggressive
        }
    }

    // MARK: - Candidate Pruning

    private func updateCandidatePlanes(opponentBoard: BoardManager) {
        let history = opponentBoard.attackHistory
        var destroyedCells = Set<String>()

        // Collect destroyed airplane cells
        for airplane in opponentBoard.airplanes where airplane.isDestroyed {
            for cell in airplane.cells {
                destroyedCells.insert("\(cell.row),\(cell.col)")
            }
        }

        // Active hits (non-destroyed airplanes)
        let destroyedIds = Set(opponentBoard.airplanes.filter { $0.isDestroyed }.map { $0.id })
        let activeHits = history.filter {
            $0.result == GameConstants.AttackResult.hit.rawValue &&
            ($0.airplaneId == nil || !destroyedIds.contains($0.airplaneId!))
        }

        // Filter candidates
        candidatePlanes = candidatePlanes.filter { plane in
            // No overlap with destroyed cells
            for cell in plane.cells {
                if destroyedCells.contains("\(cell.row),\(cell.col)") {
                    return false
                }
            }

            // No miss cells in plane
            for shot in history where shot.result == GameConstants.AttackResult.miss.rawValue {
                if plane.cells.contains(where: { $0.row == shot.row && $0.col == shot.col }) {
                    return false
                }
            }

            // Must contain all active hits
            for hit in activeHits {
                if !plane.cells.contains(where: { $0.row == hit.row && $0.col == hit.col }) {
                    return false
                }
            }

            return true
        }

        // Reinitialize if exhausted but airplanes remain
        let remainingAirplanes = opponentBoard.airplanes.filter { !$0.isDestroyed }.count
        if candidatePlanes.isEmpty && remainingAirplanes > 0 {
            initCandidatePlanes()
            candidatePlanes = candidatePlanes.filter { plane in
                for cell in plane.cells {
                    if destroyedCells.contains("\(cell.row),\(cell.col)") { return false }
                }
                for shot in history where shot.result == GameConstants.AttackResult.miss.rawValue {
                    if plane.cells.contains(where: { $0.row == shot.row && $0.col == shot.col }) { return false }
                }
                return true
            }
        }

        // Update state
        if candidatePlanes.count < 5 || activeHits.count >= 2 {
            aiState = .kill
        } else if candidatePlanes.count < 50 || activeHits.count >= 1 {
            aiState = .lock
        } else {
            aiState = .search
        }
    }

    // MARK: - Direction Probe

    private func probeDirectionFromHit(hit: AttackRecord, opponentBoard: BoardManager) -> (row: Int, col: Int)? {
        let history = opponentBoard.attackHistory
        let activeHits = history.filter { $0.result == GameConstants.AttackResult.hit.rawValue }

        // Check aligned hits
        if activeHits.count >= 2 {
            for i in 0..<activeHits.count - 1 {
                for j in (i + 1)..<activeHits.count {
                    let h1 = activeHits[i], h2 = activeHits[j]
                    if h1.row == h2.row || h1.col == h2.col {
                        if let target = findHeadFromAlignedHits(h1: h1, h2: h2, opponentBoard: opponentBoard) {
                            return target
                        }
                    }
                }
            }
        }

        // Probe adjacent to latest hit
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        var validProbes: [(row: Int, col: Int, candidates: Int)] = []

        for dir in directions {
            let r = hit.row + dir.0
            let c = hit.col + dir.1
            if r >= 0 && r < boardSize && c >= 0 && c < boardSize &&
               !opponentBoard.isCellAttacked(row: r, col: c) {
                let count = candidatePlanes.filter { plane in
                    plane.cells.contains { $0.row == r && $0.col == c }
                }.count
                validProbes.append((r, c, count))
            }
        }

        validProbes.sort { $0.candidates > $1.candidates }
        if let best = validProbes.first {
            return (best.row, best.col)
        }

        return nil
    }

    private func findHeadFromAlignedHits(h1: AttackRecord, h2: AttackRecord, opponentBoard: BoardManager) -> (row: Int, col: Int)? {
        var candidates: [(row: Int, col: Int, score: Int)] = []

        // Build head frequency map
        var headMap: [String: Int] = [:]
        for plane in candidatePlanes {
            let key = "\(plane.head.row),\(plane.head.col)"
            headMap[key, default: 0] += 1
        }

        var potentials: [(row: Int, col: Int)] = []

        if h1.row == h2.row {
            let row = h1.row
            let centerCol = (h1.col + h2.col) / 2
            potentials = [
                (row - 1, centerCol), (row + 1, centerCol),
                (row - 2, centerCol), (row + 2, centerCol)
            ]
        } else if h1.col == h2.col {
            let col = h1.col
            let minRow = min(h1.row, h2.row)
            let maxRow = max(h1.row, h2.row)
            potentials = [
                (minRow - 1, col), (maxRow + 1, col),
                (minRow - 2, col), (maxRow + 2, col)
            ]
        }

        for pos in potentials {
            if pos.0 >= 0 && pos.0 < boardSize && pos.1 >= 0 && pos.1 < boardSize &&
               !opponentBoard.isCellAttacked(row: pos.0, col: pos.1) {
                let score = headMap["\(pos.0),\(pos.1)"] ?? 0
                if score > 0 {
                    candidates.append((pos.0, pos.1, score))
                }
            }
        }

        candidates.sort { $0.score > $1.score }
        return candidates.first.map { ($0.row, $0.col) }
    }

    // MARK: - Search Shot

    private func searchShot(opponentBoard: BoardManager) -> (row: Int, col: Int)? {
        var scoreMap: [String: Double] = [:]
        let history = opponentBoard.attackHistory
        let activeHits = history.filter { $0.result == GameConstants.AttackResult.hit.rawValue }
        let misses = history.filter { $0.result == GameConstants.AttackResult.miss.rawValue }

        for plane in candidatePlanes {
            var headWeight: Double = 15

            // Edge/corner bonus
            let isEdge = plane.head.row == 0 || plane.head.row == boardSize - 1 ||
                         plane.head.col == 0 || plane.head.col == boardSize - 1
            let isCorner = (plane.head.row == 0 || plane.head.row == boardSize - 1) &&
                           (plane.head.col == 0 || plane.head.col == boardSize - 1)

            if isCorner { headWeight += 80 }
            else if isEdge { headWeight += 50 }

            // Center bonus
            let centerDist = abs(Double(plane.head.row) - Double(boardSize) / 2) +
                            abs(Double(plane.head.col) - Double(boardSize) / 2)
            if centerDist <= 2 { headWeight += 20 }

            // Nearby hits bonus
            for hit in activeHits {
                let dist = abs(plane.head.row - hit.row) + abs(plane.head.col - hit.col)
                if dist <= 3 { headWeight += 200 }
            }

            // Nearby misses penalty
            for miss in misses {
                let dist = abs(plane.head.row - miss.row) + abs(plane.head.col - miss.col)
                if dist <= 1 { headWeight -= 5 }
            }

            let headKey = "\(plane.head.row),\(plane.head.col)"
            scoreMap[headKey, default: 0] += headWeight

            // Other cells at lower weight
            for cell in plane.cells where cell.type != .head {
                let weight: Double = cell.type == .body ? 1.0 : 0.5
                let key = "\(cell.row),\(cell.col)"
                scoreMap[key, default: 0] += weight
            }
        }

        return pickMaxScoreCell(scoreMap: scoreMap, opponentBoard: opponentBoard)
    }

    // MARK: - Lock Shot

    private func lockShot(opponentBoard: BoardManager) -> (row: Int, col: Int)? {
        // Direct targeting when few candidates
        if candidatePlanes.count <= 3 {
            var targetCells: [(row: Int, col: Int, priority: Int)] = []

            for plane in candidatePlanes {
                for cell in plane.cells {
                    if !opponentBoard.isCellAttacked(row: cell.row, col: cell.col) {
                        let priority = cell.type == .head ? 1000 : (cell.type == .body ? 100 : 10)
                        targetCells.append((cell.row, cell.col, priority))
                    }
                }
            }

            targetCells.sort { $0.priority > $1.priority }
            if let target = targetCells.first {
                return (target.row, target.col)
            }
        }

        // Head frequency map
        var headMap: [String: Double] = [:]
        for plane in candidatePlanes {
            let key = "\(plane.head.row),\(plane.head.col)"
            headMap[key, default: 0] += 1
        }

        // Information gain map
        var infoGainMap: [String: Double] = [:]

        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if opponentBoard.isCellAttacked(row: row, col: col) { continue }

                // Hit eliminations: candidates NOT containing this cell
                let hitElim = candidatePlanes.filter { plane in
                    !plane.cells.contains { $0.row == row && $0.col == col }
                }.count

                // Miss eliminations: candidates containing this cell
                let missElim = candidatePlanes.filter { plane in
                    plane.cells.contains { $0.row == row && $0.col == col }
                }.count

                var infoGain = Double(min(hitElim, missElim))

                // Head bonus
                let key = "\(row),\(col)"
                if let headScore = headMap[key], headScore > 0 {
                    infoGain += headScore * 50
                }

                infoGainMap[key] = infoGain
            }
        }

        if let target = pickMaxScoreCell(scoreMap: infoGainMap, opponentBoard: opponentBoard) {
            return target
        }

        return searchShot(opponentBoard: opponentBoard)
    }

    // MARK: - Helper

    private func pickMaxScoreCell(scoreMap: [String: Double], opponentBoard: BoardManager) -> (row: Int, col: Int)? {
        var best: (row: Int, col: Int)?
        var maxScore: Double = -.infinity

        for (key, score) in scoreMap {
            let parts = key.split(separator: ",").compactMap { Int($0) }
            guard parts.count == 2 else { continue }
            let row = parts[0], col = parts[1]

            if opponentBoard.isCellAttacked(row: row, col: col) { continue }

            if score > maxScore {
                maxScore = score
                best = (row, col)
            }
        }

        return best
    }

    // MARK: - Override Process Result

    override func processAttackResult(attackPos: (row: Int, col: Int), result: (result: GameConstants.AttackResult, airplaneId: Int?, cellType: AirplaneCellType?, wasHead: Bool)) {
        super.processAttackResult(attackPos: attackPos, result: result)
        // Candidate pruning happens automatically in updateCandidatePlanes on next turn
    }

    override func reset() {
        super.reset()
        aiState = .search
        initCandidatePlanes()
    }
}
