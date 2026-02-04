import XCTest
@testable import HeadshotAirBattle

final class AirplaneTests: XCTestCase {

    // MARK: - Cell Calculation

    func testAirplaneUpHas10Cells() {
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        XCTAssertEqual(airplane.cells.count, 10, "Airplane should have exactly 10 unique cells")
    }

    func testAirplaneDownHas10Cells() {
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .down, id: 0)
        XCTAssertEqual(airplane.cells.count, 10)
    }

    func testAirplaneLeftHas10Cells() {
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .left, id: 0)
        XCTAssertEqual(airplane.cells.count, 10)
    }

    func testAirplaneRightHas10Cells() {
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .right, id: 0)
        XCTAssertEqual(airplane.cells.count, 10)
    }

    func testHeadCellIsFirst() {
        let airplane = Airplane(headRow: 3, headCol: 4, direction: .up, id: 0)
        XCTAssertEqual(airplane.cells[0].row, 3)
        XCTAssertEqual(airplane.cells[0].col, 4)
        XCTAssertEqual(airplane.cells[0].type, .head)
    }

    func testAirplaneUpStructure() {
        // Head at (0,2) pointing up on a 10x10 board
        let airplane = Airplane(headRow: 0, headCol: 2, direction: .up, id: 0)

        // Head should be at (0,2)
        XCTAssertTrue(airplane.hasCell(row: 0, col: 2))
        XCTAssertEqual(airplane.getCellType(row: 0, col: 2), .head)

        // Body extends down: (1,2), (2,2), (3,2)
        XCTAssertTrue(airplane.hasCell(row: 1, col: 2))
        XCTAssertTrue(airplane.hasCell(row: 2, col: 2))
        XCTAssertTrue(airplane.hasCell(row: 3, col: 2))

        // Wings at row 1: (1,0), (1,1), (1,3), (1,4)
        XCTAssertTrue(airplane.hasCell(row: 1, col: 0))
        XCTAssertTrue(airplane.hasCell(row: 1, col: 1))
        XCTAssertTrue(airplane.hasCell(row: 1, col: 3))
        XCTAssertTrue(airplane.hasCell(row: 1, col: 4))

        // Tail at row 3: (3,1), (3,3)
        XCTAssertTrue(airplane.hasCell(row: 3, col: 1))
        XCTAssertTrue(airplane.hasCell(row: 3, col: 3))
    }

    // MARK: - Hit Detection

    func testHeadShotKillsAirplane() {
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        let result = airplane.checkHit(row: 5, col: 5)
        XCTAssertEqual(result.result, .kill)
        XCTAssertTrue(result.wasHead)
        XCTAssertTrue(airplane.isDestroyed)
    }

    func testBodyHitDoesNotKill() {
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        let result = airplane.checkHit(row: 6, col: 5)
        XCTAssertEqual(result.result, .hit)
        XCTAssertFalse(result.wasHead)
        XCTAssertFalse(airplane.isDestroyed)
    }

    func testMissReturnsCorrectResult() {
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        let result = airplane.checkHit(row: 0, col: 0)
        XCTAssertEqual(result.result, .miss)
    }

    func testDestroyedAirplaneReturnsMiss() {
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        // Kill it
        _ = airplane.checkHit(row: 5, col: 5)
        XCTAssertTrue(airplane.isDestroyed)

        // Attack body cell of destroyed airplane
        let result = airplane.checkHit(row: 6, col: 5)
        XCTAssertEqual(result.result, .miss)
    }

    func testAllCellsHitDestroysAirplane() {
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)

        // Hit all cells except head
        for cell in airplane.cells where cell.type != .head {
            let result = airplane.checkHit(row: cell.row, col: cell.col)
            if airplane.hits.count < airplane.cells.count {
                XCTAssertEqual(result.result, .hit)
            }
        }

        // Last cell should trigger kill
        // (It depends on order - the head would be the last unhit cell)
        if !airplane.isDestroyed {
            let headResult = airplane.checkHit(row: 5, col: 5)
            XCTAssertEqual(headResult.result, .kill)
        }
        XCTAssertTrue(airplane.isDestroyed)
    }

    // MARK: - Validation

    func testValidPlacementInBounds() {
        let airplane = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        let result = airplane.isValidPlacement(boardSize: 10)
        XCTAssertTrue(result.valid)
    }

    func testInvalidPlacementOutOfBounds() {
        let airplane = Airplane(headRow: 0, headCol: 0, direction: .up, id: 0)
        let result = airplane.isValidPlacement(boardSize: 10)
        // Wings extend to col -2, -1 which is out of bounds
        XCTAssertFalse(result.valid)
    }

    func testOverlapDetection() {
        let airplane1 = Airplane(headRow: 5, headCol: 5, direction: .up, id: 0)
        let airplane2 = Airplane(headRow: 5, headCol: 5, direction: .down, id: 1)
        let result = airplane2.isValidPlacement(boardSize: 10, existingAirplanes: [airplane1])
        XCTAssertFalse(result.valid)
    }

    // MARK: - Random Placement

    func testRandomPlacement() {
        let airplane = Airplane.createRandom(boardSize: 10, existingAirplanes: [], id: 0)
        XCTAssertNotNil(airplane)
        XCTAssertEqual(airplane?.cells.count, 10)
    }

    // MARK: - Serialization

    func testSerialization() {
        let original = Airplane(headRow: 3, headCol: 4, direction: .left, id: 7)
        _ = original.checkHit(row: 3, col: 4) // Kill head

        let data = original.toData()
        let restored = Airplane.fromData(data)

        XCTAssertEqual(restored.headRow, 3)
        XCTAssertEqual(restored.headCol, 4)
        XCTAssertEqual(restored.direction, .left)
        XCTAssertEqual(restored.id, 7)
        XCTAssertTrue(restored.isDestroyed)
    }
}
