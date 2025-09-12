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
    private func index(row: Int, column: Int) -> Int { row * width + column}
    
    // Returns true if a row/column is inside the board - ensure don't go off board
    private func isValid(_ row: Int, _ column: Int) -> Bool {
        row >= 0 && row < height && column >= 0 && column < width
    }
    
    private func neighbors(of row: Int, _ column: Int) -> [(Int, Int)] {
        var out: [(Int, Int)] = []
        for drow in -1...1 {
            for dcolumn in -1...1 {
                if drow == 0 && dcolumn == 0 { continue } // skip the center cell/self
                let rowNeighbor = row + drow
                let rowColumn = column + dcolumn
                if isValid(rowNeighbor, rowColumn) {
                    out.append((rowNeighbor, rowColumn))
                }
            }
        }
        return out
    }
    
    // WIP
    private func desiredMineCount(for density: Double) -> Int {
        let totalCells = width * height - 1 // no. of cells, -1 for *this* cell
        let rawMineCount = Double(totalCells) * density
        let roundedMineCount = Int(rawMineCount.rounded())
        let maxCellsAllowedToHaveMines: Int = min(roundedMineCount, totalCells) // all but one cell can have a mine
        return max(1, maxCellsAllowedToHaveMines) // have at least one mine
    }
    
    func reveal(row: Int, column: Int) {
        let i = index(row: row, column: column)
        guard cells.indices.contains(i) else { return }
        if cells[i].state == .covered {
            cells[i].state = .revealed
        }
    }
    
    func toggleFlag(row: Int, column: Int) {
        let i = index(row: row, column: column)
        guard cells.indices.contains(i) else { return }
        switch cells[i].state {
            case .covered: cells[i].state = .flagged
            case .flagged: cells[i].state = .covered
            case .revealed: break
        }
    }
}
