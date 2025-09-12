//
//  ContentView.swift
//  MineSweeper
//
//  Created by Roxana del Toro Lopez on 9/10/25.
//

import SwiftUI

struct GameView: View {
    @StateObject private var board = Board(width: 10, height: 10)
    
    var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 2),
            count: board.width
        )
        
        VStack(spacing: 8) {
            Text("MineSweeper").font(.title2).bold()
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(board.cells) { cell in
                    CellView(cell: cell).onTapGesture {
                        board.reveal(row: cell.row, column: cell.column)
                    }.contextMenu { // right click to flag (optional)
                        Button(cell.state == .flagged ? "Unflag" : "Flag") {
                            board.toggleFlag(row: cell.row, column: cell.column)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: 500)
        }
        .padding()
    }
}

#Preview {
    GameView()
}

struct CellView: View {
    let cell: Cell
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.blue)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
            switch cell.state {
            case .covered: EmptyView()
            case .flagged: Text("🚩")
            case .revealed:
                // Placeholder: show coordinates until we compute numbers
                Text("\(cell.row),\(cell.column)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
            }
        }
        .aspectRatio(1, contentMode: .fit) // keep squares
        .contentShape(Rectangle()) // make taps easier
    }
    
    private var backgroundColor: Color {
        switch cell.state {
        case .covered: return Color.gray.opacity(0.35)
        case .flagged: return Color.orange.opacity(0.35)
        case .revealed: return Color.gray.opacity(0.1)
        }
    }
}

