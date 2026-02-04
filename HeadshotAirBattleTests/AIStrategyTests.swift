import XCTest
@testable import HeadshotAirBattle

final class AIStrategyTests: XCTestCase {

    // MARK: - Easy AI

    func testEasyAIReturnsValidTarget() {
        let board = BoardManager(size: 10, airplaneCount: 3)
        _ = board.placeAirplanesRandomly()

        let ai = AIStrategy(difficulty: .easy, boardSize: 10)
        let target = ai.getNextAttack(opponentBoard: board)

        XCTAssertNotNil(target)
        XCTAssertTrue(target!.row >= 0 && target!.row < 10)
        XCTAssertTrue(target!.col >= 0 && target!.col < 10)
    }

    func testEasyAIDoesNotRepeatCells() {
        let board = BoardManager(size: 10, airplaneCount: 3)
        _ = board.placeAirplanesRandomly()

        let ai = AIStrategy(difficulty: .easy, boardSize: 10)
        var attackedCells = Set<String>()

        for _ in 0..<50 {
            guard let target = ai.getNextAttack(opponentBoard: board) else { break }
            let key = "\(target.row),\(target.col)"
            XCTAssertFalse(attackedCells.contains(key), "AI should not suggest already-attacked cell")

            // Process the attack to mark cell as attacked
            _ = board.processAttack(row: target.row, col: target.col)
            attackedCells.insert(key)
        }
    }

    // MARK: - Medium AI

    func testMediumAIFollowsUpHits() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        _ = board.addAirplane(airplane)

        let ai = AIStrategy(difficulty: .medium, boardSize: 10)

        // Simulate a hit on body
        let hitResult = board.processAttack(row: 6, col: 5)
        ai.processAttackResult(attackPos: (6, 5), result: hitResult)

        // Medium AI should now have adjacent cells in queue
        XCTAssertFalse(ai.targetQueue.isEmpty, "Medium AI should queue adjacent cells after hit")

        // Next attack should be from queue (adjacent to hit)
        let nextTarget = ai.getNextAttack(opponentBoard: board)
        XCTAssertNotNil(nextTarget)

        if let target = nextTarget {
            let distance = abs(target.row - 6) + abs(target.col - 5)
            XCTAssertEqual(distance, 1, "Next target should be adjacent to the hit")
        }
    }

    // MARK: - Hard AI

    func testHardAIInitialization() {
        let ai = AIStrategyHard(boardSize: 10)
        XCTAssertNotNil(ai)
    }

    func testHardAIReturnsValidTarget() {
        let board = BoardManager(size: 10, airplaneCount: 3)
        _ = board.placeAirplanesRandomly()

        let ai = AIStrategyHard(boardSize: 10)
        let target = ai.getNextAttack(opponentBoard: board)

        XCTAssertNotNil(target)
        if let target = target {
            XCTAssertTrue(target.row >= 0 && target.row < 10)
            XCTAssertTrue(target.col >= 0 && target.col < 10)
        }
    }

    func testHardAIOpensWithCenter() {
        let board = BoardManager(size: 10, airplaneCount: 3)
        _ = board.placeAirplanesRandomly()

        let ai = AIStrategyHard(boardSize: 10)
        let target = ai.getNextAttack(opponentBoard: board)

        XCTAssertNotNil(target)
        // First move should be center (5, 5)
        XCTAssertEqual(target?.row, 5)
        XCTAssertEqual(target?.col, 5)
    }

    // MARK: - AI Factory

    func testAIFactory() {
        let easy = AIStrategy.create(difficulty: .easy, boardSize: 10)
        XCTAssertEqual(easy.difficulty, .easy)

        let medium = AIStrategy.create(difficulty: .medium, boardSize: 10)
        XCTAssertEqual(medium.difficulty, .medium)

        let hard = AIStrategy.create(difficulty: .hard, boardSize: 10)
        XCTAssertTrue(hard is AIStrategyHard)
    }

    // MARK: - Complete Game Simulation

    func testCompleteGameAgainstEasyAI() {
        let playerBoard = BoardManager(size: 10, airplaneCount: 3)
        let aiBoard = BoardManager(size: 10, airplaneCount: 3)

        XCTAssertTrue(playerBoard.placeAirplanesRandomly())
        XCTAssertTrue(aiBoard.placeAirplanesRandomly())

        let ai = AIStrategy(difficulty: .easy, boardSize: 10)
        var turns = 0
        let maxTurns = 200

        while turns < maxTurns {
            // Player attacks AI board (randomly for this test)
            var attacked = false
            for row in 0..<10 {
                for col in 0..<10 {
                    if !aiBoard.isCellAttacked(row: row, col: col) {
                        _ = aiBoard.processAttack(row: row, col: col)
                        attacked = true
                        break
                    }
                }
                if attacked { break }
            }
            turns += 1

            if aiBoard.areAllAirplanesDestroyed() { break }

            // AI attacks player board
            guard let target = ai.getNextAttack(opponentBoard: playerBoard) else { break }
            let result = playerBoard.processAttack(row: target.row, col: target.col)
            ai.processAttackResult(attackPos: target, result: result)
            turns += 1

            if playerBoard.areAllAirplanesDestroyed() { break }
        }

        // Game should have ended
        XCTAssertTrue(
            aiBoard.areAllAirplanesDestroyed() || playerBoard.areAllAirplanesDestroyed(),
            "Game should end within \(maxTurns) turns"
        )
    }
}
