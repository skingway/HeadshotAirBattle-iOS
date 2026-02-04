import Foundation

/// AI strategy protocol and basic implementations (Easy + Medium)
class AIStrategy {
    let difficulty: GameConstants.AIDifficulty
    let boardSize: Int
    var targetQueue: [(row: Int, col: Int)] = []
    var lastHit: (row: Int, col: Int)?
    var hitSequence: [(row: Int, col: Int)] = []

    init(difficulty: GameConstants.AIDifficulty, boardSize: Int) {
        self.difficulty = difficulty
        self.boardSize = boardSize
    }

    /// Factory method to create the right AI for the difficulty level
    static func create(difficulty: GameConstants.AIDifficulty, boardSize: Int) -> AIStrategy {
        switch difficulty {
        case .hard:
            return AIStrategyHard(boardSize: boardSize)
        default:
            return AIStrategy(difficulty: difficulty, boardSize: boardSize)
        }
    }

    // MARK: - Main Attack Method

    func getNextAttack(opponentBoard: BoardManager) -> (row: Int, col: Int)? {
        switch difficulty {
        case .easy:
            return getRandomAttack(opponentBoard: opponentBoard)
        case .medium:
            return getMediumAttack(opponentBoard: opponentBoard)
        case .hard:
            return getHardAttack(opponentBoard: opponentBoard)
        }
    }

    // MARK: - Easy AI: Random

    func getRandomAttack(opponentBoard: BoardManager) -> (row: Int, col: Int)? {
        var availableCells: [(row: Int, col: Int)] = []

        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if !opponentBoard.isCellAttacked(row: row, col: col) {
                    availableCells.append((row, col))
                }
            }
        }

        guard !availableCells.isEmpty else { return nil }
        return availableCells.randomElement()
    }

    // MARK: - Medium AI: Follow-up on Hits

    func getMediumAttack(opponentBoard: BoardManager) -> (row: Int, col: Int)? {
        // Try targets from queue first
        while !targetQueue.isEmpty {
            let target = targetQueue.removeFirst()
            if !opponentBoard.isCellAttacked(row: target.row, col: target.col) {
                return target
            }
        }

        // Fall back to random
        return getRandomAttack(opponentBoard: opponentBoard)
    }

    // MARK: - Hard AI (overridden in AIStrategyHard)

    func getHardAttack(opponentBoard: BoardManager) -> (row: Int, col: Int)? {
        return getRandomAttack(opponentBoard: opponentBoard)
    }

    // MARK: - Process Attack Result

    func processAttackResult(attackPos: (row: Int, col: Int), result: (result: GameConstants.AttackResult, airplaneId: Int?, cellType: AirplaneCellType?, wasHead: Bool)) {
        if result.result == .hit {
            lastHit = attackPos
            hitSequence.append(attackPos)

            // Add adjacent cells to investigate
            let adjacentCells = CoordinateSystem.getAdjacentPositions(row: attackPos.row, col: attackPos.col, boardSize: boardSize)

            if hitSequence.count > 1 {
                // Determine direction of hits
                let prevHit = hitSequence[hitSequence.count - 2]
                let isHorizontal = attackPos.row == prevHit.row
                let isVertical = attackPos.col == prevHit.col

                for cell in adjacentCells {
                    if (isHorizontal && cell.row == attackPos.row) ||
                       (isVertical && cell.col == attackPos.col) {
                        targetQueue.insert(cell, at: 0) // Priority
                    } else {
                        targetQueue.append(cell)
                    }
                }
            } else {
                // First hit - add all adjacent
                targetQueue.append(contentsOf: adjacentCells)
            }
        } else if result.result == .kill {
            // Clear queue for destroyed airplane
            targetQueue.removeAll()
            lastHit = nil
            hitSequence.removeAll()
        }
    }

    func reset() {
        targetQueue.removeAll()
        lastHit = nil
        hitSequence.removeAll()
    }
}
