//
//  ContentView.swift
//  MineSweeper
//
//  Created by Roxana del Toro Lopez on 9/10/25.
//

#if os(macOS)
import AppKit
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
                    CellView(cell: cell)
                        .contentShape(Rectangle()) // make taps easier
                        .onSingleAndDoubleClick(
                            single: {
                                print("single @ (\(cell.row),\(cell.column))")
                                board.revealCell(row: cell.row, column: cell.column)
                            },
                            double: {
                                print("double @ (\(cell.row),\(cell.column))")
                                board.toggleFlag(row: cell.row, column: cell.column)
                            }
                        )
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
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
            switch cell.state {
            case .covered: EmptyView()
            case .flagged: Text("🚩")
            case .revealed:
                if cell.isAMine {
                    Text("💣")
                } else if cell.adjacentMineCount > 0 {
                    Text("\(cell.adjacentMineCount)").font(.system(size: 14, weight: .bold))
                } else {
                    // adjacent == 0 so show nothing
                    EmptyView()
                }
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

// Copied from online
// Robust macOS single vs double click using two NSClickGestureRecognizers with a delegate.
// The single is required to FAIL if the double succeeds, and vice-versa,
// so only one of them fires per interaction.
private struct ClickOverlay: NSViewRepresentable {
    let onSingle: () -> Void
    let onDouble: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onSingle: onSingle, onDouble: onDouble) }

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.clear.cgColor

        let single = NSClickGestureRecognizer(target: context.coordinator,
                                              action: #selector(Coordinator.handleSingle))
        single.numberOfClicksRequired = 1
        single.buttonMask = 0x1 // primary button
        single.delegate = context.coordinator

        let dbl = NSClickGestureRecognizer(target: context.coordinator,
                                           action: #selector(Coordinator.handleDouble))
        dbl.numberOfClicksRequired = 2
        dbl.buttonMask = 0x1 // primary button
        dbl.delegate = context.coordinator

        context.coordinator.single = single
        context.coordinator.double = dbl

        // Add both recognizers
        v.addGestureRecognizer(dbl)
        v.addGestureRecognizer(single)
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    final class Coordinator: NSObject, NSGestureRecognizerDelegate {
        let onSingle: () -> Void
        let onDouble: () -> Void
        weak var single: NSClickGestureRecognizer?
        weak var double: NSClickGestureRecognizer?

        // We’ll schedule single and cancel it if the system recognizes a double.
        private var pendingSingle: DispatchWorkItem?

        init(onSingle: @escaping () -> Void, onDouble: @escaping () -> Void) {
            self.onSingle = onSingle
            self.onDouble = onDouble
        }

        // Ensure exclusivity in both directions.
        func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer,
                               shouldRequireFailureOf other: NSGestureRecognizer) -> Bool {
            // single waits to see if double wins
            return (gestureRecognizer === single && other === double)
        }
        func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer,
                               shouldBeRequiredToFailBy other: NSGestureRecognizer) -> Bool {
            // double should not be blocked by single
            return (gestureRecognizer === double && other === single)
        }

        @objc func handleDouble() {
            // Cancel any scheduled single and fire double immediately.
            pendingSingle?.cancel(); pendingSingle = nil
            onDouble()
        }

        @objc func handleSingle() {
            // Delay single by the system interval; if a double arrives, it will cancel this.
            pendingSingle?.cancel()
            let work = DispatchWorkItem { [onSingle] in onSingle() }
            pendingSingle = work
            DispatchQueue.main.asyncAfter(
                deadline: .now() + NSEvent.doubleClickInterval,
                execute: work
            )
        }
    }
}

extension View {
    /// Attach macOS single/double click handlers that are mutually exclusive and reliable.
    func onSingleAndDoubleClick(single: @escaping () -> Void,
                                double: @escaping () -> Void) -> some View {
        overlay(ClickOverlay(onSingle: single, onDouble: double))
    }
}
#endif

// Copied from online

