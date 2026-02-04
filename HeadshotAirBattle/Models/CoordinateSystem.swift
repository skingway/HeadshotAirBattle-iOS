import Foundation

/// Coordinate system for converting between array indices and human-readable coordinates
/// Supports boards larger than 26 columns (A-Z, AA-AZ, BA-BZ, etc.)
enum CoordinateSystem {

    /// Convert column index (0-based) to letter(s): 0->A, 25->Z, 26->AA
    static func indexToLetter(_ index: Int) -> String {
        var result = ""
        var num = index

        while num >= 0 {
            result = String(Character(UnicodeScalar(65 + (num % 26))!)) + result
            num = num / 26 - 1
            if num < 0 { break }
        }

        return result
    }

    /// Convert letter(s) to column index (0-based): A->0, Z->25, AA->26
    static func letterToIndex(_ letter: String) -> Int {
        var result = 0
        let upperLetter = letter.uppercased()

        for char in upperLetter {
            guard let ascii = char.asciiValue else { return 0 }
            result = result * 26 + Int(ascii) - 64
        }

        return result - 1
    }

    /// Convert grid position to coordinate string: (0,0)->"1A", (9,25)->"10Z"
    static func positionToCoordinate(row: Int, col: Int) -> String {
        let rowNumber = row + 1
        let colLetter = indexToLetter(col)
        return "\(rowNumber)\(colLetter)"
    }

    /// Parse coordinate string to grid position: "1A"->(0,0), "10Z"->(9,25)
    static func coordinateToPosition(_ coordinate: String) -> (row: Int, col: Int)? {
        let pattern = "^(\\d+)([A-Za-z]+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: coordinate, range: NSRange(coordinate.startIndex..., in: coordinate)) else {
            return nil
        }

        guard let rowRange = Range(match.range(at: 1), in: coordinate),
              let colRange = Range(match.range(at: 2), in: coordinate) else {
            return nil
        }

        let rowNumber = Int(coordinate[rowRange]) ?? 0
        let colLetter = String(coordinate[colRange])

        return (row: rowNumber - 1, col: letterToIndex(colLetter))
    }

    /// Generate array of column labels for a given board width
    static func generateColumnLabels(width: Int) -> [String] {
        return (0..<width).map { indexToLetter($0) }
    }

    /// Generate array of row labels for a given board height
    static func generateRowLabels(height: Int) -> [String] {
        return (1...height).map { "\($0)" }
    }

    /// Validate if position is within board bounds
    static func isWithinBounds(row: Int, col: Int, boardSize: Int) -> Bool {
        return row >= 0 && row < boardSize && col >= 0 && col < boardSize
    }

    /// Get adjacent cell positions (up, down, left, right)
    static func getAdjacentPositions(row: Int, col: Int, boardSize: Int) -> [(row: Int, col: Int)] {
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        return directions
            .map { (row + $0.0, col + $0.1) }
            .filter { isWithinBounds(row: $0.0, col: $0.1, boardSize: boardSize) }
    }
}
