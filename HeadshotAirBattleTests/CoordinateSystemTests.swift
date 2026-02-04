import XCTest
@testable import HeadshotAirBattle

final class CoordinateSystemTests: XCTestCase {

    func testIndexToLetter() {
        XCTAssertEqual(CoordinateSystem.indexToLetter(0), "A")
        XCTAssertEqual(CoordinateSystem.indexToLetter(1), "B")
        XCTAssertEqual(CoordinateSystem.indexToLetter(25), "Z")
        XCTAssertEqual(CoordinateSystem.indexToLetter(26), "AA")
        XCTAssertEqual(CoordinateSystem.indexToLetter(27), "AB")
    }

    func testLetterToIndex() {
        XCTAssertEqual(CoordinateSystem.letterToIndex("A"), 0)
        XCTAssertEqual(CoordinateSystem.letterToIndex("B"), 1)
        XCTAssertEqual(CoordinateSystem.letterToIndex("Z"), 25)
        XCTAssertEqual(CoordinateSystem.letterToIndex("AA"), 26)
        XCTAssertEqual(CoordinateSystem.letterToIndex("AB"), 27)
    }

    func testPositionToCoordinate() {
        XCTAssertEqual(CoordinateSystem.positionToCoordinate(row: 0, col: 0), "1A")
        XCTAssertEqual(CoordinateSystem.positionToCoordinate(row: 9, col: 25), "10Z")
        XCTAssertEqual(CoordinateSystem.positionToCoordinate(row: 4, col: 26), "5AA")
    }

    func testCoordinateToPosition() {
        let pos1 = CoordinateSystem.coordinateToPosition("1A")
        XCTAssertEqual(pos1?.row, 0)
        XCTAssertEqual(pos1?.col, 0)

        let pos2 = CoordinateSystem.coordinateToPosition("10Z")
        XCTAssertEqual(pos2?.row, 9)
        XCTAssertEqual(pos2?.col, 25)
    }

    func testRoundTrip() {
        for row in 0..<20 {
            for col in 0..<20 {
                let coord = CoordinateSystem.positionToCoordinate(row: row, col: col)
                let pos = CoordinateSystem.coordinateToPosition(coord)
                XCTAssertEqual(pos?.row, row, "Row mismatch for \(coord)")
                XCTAssertEqual(pos?.col, col, "Col mismatch for \(coord)")
            }
        }
    }

    func testColumnLabels() {
        let labels = CoordinateSystem.generateColumnLabels(width: 10)
        XCTAssertEqual(labels.count, 10)
        XCTAssertEqual(labels[0], "A")
        XCTAssertEqual(labels[9], "J")
    }

    func testRowLabels() {
        let labels = CoordinateSystem.generateRowLabels(height: 10)
        XCTAssertEqual(labels.count, 10)
        XCTAssertEqual(labels[0], "1")
        XCTAssertEqual(labels[9], "10")
    }

    func testAdjacentPositions() {
        let adjacent = CoordinateSystem.getAdjacentPositions(row: 5, col: 5, boardSize: 10)
        XCTAssertEqual(adjacent.count, 4)

        // Corner has only 2
        let corner = CoordinateSystem.getAdjacentPositions(row: 0, col: 0, boardSize: 10)
        XCTAssertEqual(corner.count, 2)

        // Edge has 3
        let edge = CoordinateSystem.getAdjacentPositions(row: 0, col: 5, boardSize: 10)
        XCTAssertEqual(edge.count, 3)
    }

    func testIsWithinBounds() {
        XCTAssertTrue(CoordinateSystem.isWithinBounds(row: 0, col: 0, boardSize: 10))
        XCTAssertTrue(CoordinateSystem.isWithinBounds(row: 9, col: 9, boardSize: 10))
        XCTAssertFalse(CoordinateSystem.isWithinBounds(row: -1, col: 0, boardSize: 10))
        XCTAssertFalse(CoordinateSystem.isWithinBounds(row: 10, col: 0, boardSize: 10))
    }
}
