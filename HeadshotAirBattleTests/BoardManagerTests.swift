import XCTest
@testable import HeadshotAirBattle

final class BoardManagerTests: XCTestCase {

    // MARK: - Placement

    func testAddAirplane() {
        let board = BoardManager(size: 10, airplaneCount: 3)
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        let result = board.addAirplane(airplane)
        XCTAssertTrue(result.success)
        XCTAssertEqual(board.airplanes.count, 1)
    }

    func testMaxAirplaneLimit() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        let airplane1 = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        _ = board.addAirplane(airplane1)

        let airplane2 = Airplane(headRow: 2, headCol: 2, direction: .down, id: 1)
        let result = board.addAirplane(airplane2)
        XCTAssertFalse(result.success)
    }

    func testRemoveAirplane() {
        let board = BoardManager(size: 10, airplaneCount: 3)
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        _ = board.addAirplane(airplane)
        XCTAssertTrue(board.removeAirplane(id: 0))
        XCTAssertEqual(board.airplanes.count, 0)
    }

    func testRandomPlacement() {
        let board = BoardManager(size: 10, airplaneCount: 3)
        let success = board.placeAirplanesRandomly()
        XCTAssertTrue(success)
        XCTAssertEqual(board.airplanes.count, 3)
    }

    func testRandomPlacementLargeBoard() {
        let board = BoardManager(size: 15, airplaneCount: 6)
        let success = board.placeAirplanesRandomly()
        XCTAssertTrue(success)
        XCTAssertEqual(board.airplanes.count, 6)
    }

    // MARK: - Attack Processing

    func testProcessAttackMiss() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        _ = board.addAirplane(airplane)

        let result = board.processAttack(row: 0, col: 0)
        XCTAssertEqual(result.result, .miss)
        XCTAssertNil(result.airplaneId)
    }

    func testProcessAttackHit() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        _ = board.addAirplane(airplane)

        // Hit body cell
        let result = board.processAttack(row: 6, col: 5)
        XCTAssertEqual(result.result, .hit)
        XCTAssertEqual(result.airplaneId, 0)
    }

    func testProcessAttackKill() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        _ = board.addAirplane(airplane)

        // Hit head = instant kill
        let result = board.processAttack(row: 5, col: 5)
        XCTAssertEqual(result.result, .kill)
        XCTAssertTrue(result.wasHead)
    }

    func testAlreadyAttacked() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        _ = board.addAirplane(airplane)

        _ = board.processAttack(row: 0, col: 0)
        let result = board.processAttack(row: 0, col: 0)
        XCTAssertEqual(result.result, .alreadyAttacked)
    }

    func testOutOfBounds() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        let result = board.processAttack(row: -1, col: 0)
        XCTAssertEqual(result.result, .invalid)
    }

    // MARK: - State Queries

    func testAreAllAirplanesDestroyed() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        _ = board.addAirplane(airplane)

        XCTAssertFalse(board.areAllAirplanesDestroyed())

        _ = board.processAttack(row: 5, col: 5) // Kill head
        XCTAssertTrue(board.areAllAirplanesDestroyed())
    }

    func testRemainingAirplaneCount() {
        let board = BoardManager(size: 10, airplaneCount: 3)
        _ = board.placeAirplanesRandomly()

        XCTAssertEqual(board.getRemainingAirplaneCount(), 3)

        // Kill first airplane's head
        let head = board.airplanes[0]
        _ = board.processAttack(row: head.headRow, col: head.headCol)

        XCTAssertEqual(board.getRemainingAirplaneCount(), 2)
    }

    // MARK: - Cell State

    func testCellStateEmpty() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        let state = board.getCellState(row: 0, col: 0)
        XCTAssertEqual(state, .empty)
    }

    func testCellStateRevealAirplane() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        _ = board.addAirplane(airplane)

        let state = board.getCellState(row: 5, col: 5, revealAirplanes: true)
        XCTAssertEqual(state, .airplane)
    }

    func testCellStateHiddenAirplane() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        _ = board.addAirplane(airplane)

        let state = board.getCellState(row: 5, col: 5, revealAirplanes: false)
        XCTAssertEqual(state, .empty)
    }

    // MARK: - Statistics

    func testStatistics() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        _ = board.addAirplane(airplane)

        // Miss
        _ = board.processAttack(row: 0, col: 0)
        // Hit (body)
        _ = board.processAttack(row: 6, col: 5)

        let stats = board.getStatistics()
        XCTAssertEqual(stats.hits, 1)
        XCTAssertEqual(stats.misses, 1)
    }

    // MARK: - Deployment

    func testDeploymentComplete() {
        let board = BoardManager(size: 10, airplaneCount: 1)
        XCTAssertFalse(board.isDeploymentComplete())

        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        _ = board.addAirplane(airplane)
        XCTAssertTrue(board.isDeploymentComplete())
    }
}
