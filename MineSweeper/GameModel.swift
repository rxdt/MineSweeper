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
    var isAMine: Bool = false
    var adjacentMineCount: Int = 0 // 0 to 8 neighbors i.e. 0-8 mines adjacent
}

final class Board: ObservableObject {
    @Published var width: Int
    @Published var height: Int
    // Our 'board' data structure is a 1D array of Cell objects
    // Cell: index = row * width + column, row = index / width, column = index % width
    @Published var cells: [Cell]
    
    private var minesPlaced = false
    
    init(width: Int = 10, height: Int = 10) {
        self.width = width
        self.height = height
        self.cells = []
        for row in 0..<height {
            for column in 0..<width {
                cells.append(Cell(row: row, column: column))
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
    private func getNeighbors(row: Int, column: Int) -> [(Int, Int)] {
        var neighborsRowsAndColumns: [(Int, Int)] = []
        for row in -1...1 {
            for column in -1...1 {
                if row == 0 && column == 0 { continue } // skip the center cell/self
                let rowNeighbor = row + row
                let columnNeighbor = column + column
                if isValid(rowNeighbor, columnNeighbor) {
                    neighborsRowsAndColumns.append((rowNeighbor, columnNeighbor))
                }
            }
        }
        return neighborsRowsAndColumns
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
            cells[i].isAMine = true
        }
        
        // count how many mines are nearby and set each cell's count
        for idx in mineIndices {
            let row = idx / width
            let column = idx % width
            // for each mine, bump the # on surrounding non-mine cells
            for (neighborRow, neighborColumn) in getNeighbors(row: row, column: column) {
                // if this neighbor is not a mine...
                let neighborIndex = getIndexGivenRowColumn(row: neighborRow, column: neighborColumn)
                // then increment neighbor's adjacent mine count
                if !cells[neighborIndex].isAMine { cells[neighborIndex].adjacentMineCount += 1 }
            }
        }
        minesPlaced = true
    }
    
    func revealCell(row: Int, column: Int) {
        if !minesPlaced { placeMines(safeRow: row, safeColumn: column)}
        let idxOfThisCell = getIndexGivenRowColumn(row: row, column: column)
        guard cells.indices.contains(idxOfThisCell) else { return }
        guard cells[idxOfThisCell].state == .covered else { return }
        
        if cells[idxOfThisCell].isAMine {
            objectWillChange.send()
            cells[idxOfThisCell].state = .revealed
//            gameOver = true
            return
        }
        
        if cells[idxOfThisCell].adjacentMineCount == 0 {
            floodReveal(startRow: row, startColumn: column)
        } else {
            objectWillChange.send()
            cells[idxOfThisCell].state = .revealed
        }
    }
    
    func toggleFlag(row: Int, column: Int) {
        let i = getIndexGivenRowColumn(row: row, column: column)
        guard cells.indices.contains(i) else { return }
        objectWillChange.send() // publish UI update
        switch cells[i].state {
            case .covered: cells[i].state = .flagged
            case .flagged: cells[i].state = .covered
            case .revealed: break
        }
    }
    
    // Zeros trigger the region-open DFS; otherwise just reveal a single numbered tile.
    // Reveal a blank region: opens cells with no mines at center and a numbered border
    private func floodReveal(startRow: Int, startColumn: Int) {
        objectWillChange.send()
        // seed stack of tuples with starting cell
        var stack: [(Int, Int)] = [(startRow, startColumn)]
        // set of ints with visited indices
        var visited = Set<Int>()
        // Assigns non-nil value and enters loop; when popLast() returns nil, loop ends
        // While the stack still has a cell, pop it and work on its (row, column)
        while let (row, column) = stack.popLast() { // DFS
            // get index from 1D cells array aka board, of the tuple jost got from stack
            let idx = getIndexGivenRowColumn(row: row, column: column)
            // If idx is not valid, skip this iteration and moves to the next loop
            if !cells.indices.contains(idx) { continue }
            // if we've already processed this cell, skip this iteration
            if visited.contains(idx) { continue }
            // if was unvisited, not it was, so mark it as visited
            visited.insert(idx)
            
            // flagged and revealed tiles are ignored - only reveal covered, non-mine tiles
            if cells[idx].state != .covered { continue }
            if cells[idx].isAMine { continue }
            cells[idx].state = .revealed
            
            // if a cell is blank and has no mines near it
            if cells[idx].adjacentMineCount == 0 {
                for (neighborRow, neighborColumn) in getNeighbors(row: row, column: column) {
                    let neighborIdx = getIndexGivenRowColumn(row: neighborRow, column: neighborColumn)
                    if cells.indices.contains(neighborIdx),
                       cells[neighborIdx].state == .covered,
                       !cells[neighborIdx].isAMine {
                        stack.append((neighborRow, neighborColumn))
                    }
                }
            }
        }
    }
}
