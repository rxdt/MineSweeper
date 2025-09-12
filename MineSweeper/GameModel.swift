//
//  GameModel.swift
//  MineSweeper
//
//  Created by Roxana del Toro Lopez on 9/10/25.
//
import Foundation
import Combine

enum CellState { case covered, revealed, flagged }

struct Cell: Identifiable, Hashable {
    let id = UUID()
    let row: Int
    let column: Int
    var state: CellState = .covered
    var isMine: Bool = false
    var adjacent: Int = 0 // 0 to 8 neighbors i.e. 0-8 mines adjacent
}

final class Board: ObservableObject {
    @Published var width: Int
    @Published var height: Int
    @Published var cells: [Cell]
    
    private var minesPlaced = false
    
    init(width: Int = 10, height: Int = 10) {
        self.width = width
        self.height = height
        self.cells = []
        for row_ in 0..<height {
            for column_ in 0..<width {
                cells.append(Cell(row: row_, column: column_))
            }
        }
    }
    
    // grid is a 1D array, this formula gets the index of a cell
    private func getIndexGivenRowColumn(row: Int, column: Int) -> Int { row * width + column}
    
    // Returns true if a row/column is inside the board - ensure don't go off board
    private func isValid(_ row: Int, _ column: Int) -> Bool {
        row >= 0 && row < height && column >= 0 && column < width
    }
    
    // Get each neighbor's row/column
    private func neighbors(row: Int, column: Int) -> [(Int, Int)] {
        var out: [(Int, Int)] = []
        for drow in -1...1 {
            for dcolumn in -1...1 {
                if drow == 0 && dcolumn == 0 { continue } // skip the center cell/self
                let rowNeighbor = row + drow
                let columnNeighbor = column + dcolumn
                if isValid(rowNeighbor, columnNeighbor) {
                    out.append((rowNeighbor, columnNeighbor))
                }
            }
        }
        return out
    }
    
    // Places mines on first click
    private func placeMines(safeRow rowZero: Int, safeColumn columnZero: Int, density: Double = 0.159) {
        // ensure first clicked cell is never a mine
        let firstClickedCellIndex = getIndexGivenRowColumn(row: rowZero, column: columnZero)
        // allowable pool of cells
        var candidateMines: [Int] = []
        for idx in 0..<(width * height) {
            if idx != firstClickedCellIndex {
                candidateMines.append(idx)
            }
        }

        // have at least one mine, and all but one cell can have a mine
        let desiredMineCount = Int((Double(candidateMines.count) * density).rounded())
        // never less than 1, and never more than # of candidateMines
        let mineCount = max(1, min(desiredMineCount, candidateMines.count))

        // randomize candidate indices
        candidateMines.shuffle()
        // take first k without duplicates
        let mineIndices = candidateMines.prefix(mineCount)
        for i in mineIndices {
            cells[i].isMine = true
        }
        
        // count how many mines are nearby and set each cell's count
        for idx in mineIndices {
            let row = idx / width
            let column = idx % width
            // for each mine, bump the # on surrounding non-mine cells
            for (neighborRow, neighborColumn) in neighbors(row: row, column: column) {
                // if this neighbor is not a mine...
                let neighborIndex = getIndexGivenRowColumn(row: neighborRow, column: neighborColumn)
                // then increment neighbor's adjacent mine count
                if !cells[neighborIndex].isMine { cells[neighborIndex].adjacent += 1 }
            }
        }
        minesPlaced = true
    }
    
    func reveal(row: Int, column: Int) {
        if !minesPlaced { placeMines(safeRow: row, safeColumn: column)}
        let i = getIndexGivenRowColumn(row: row, column: column)
        guard cells.indices.contains(i) else { return }
        if cells[i].state == .covered {
            cells[i].state = .revealed
        }
    }
    
    func toggleFlag(row: Int, column: Int) {
        let i = getIndexGivenRowColumn(row: row, column: column)
        guard cells.indices.contains(i) else { return }
        switch cells[i].state {
            case .covered: cells[i].state = .flagged
            case .flagged: cells[i].state = .covered
            case .revealed: break
        }
    }
}
