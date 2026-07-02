import CorkCore
import AppKit
import SwiftUI

struct BoardView: View {
    @ObservedObject var boardStore: BoardStore

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .opacity(0.45)

            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    BoardCanvasBackground()
                        .zIndex(0)

                    ForEach(boardStore.selectedBoard.items) { item in
                        BoardCardView(
                            item: item,
                            isSelected: item.id == boardStore.selectedItemID
                        )
                    }

                    BoardMouseInputView(
                        items: boardStore.selectedBoard.items,
                        selectedItemID: boardStore.selectedItemID,
                        boardSize: boardSize(from: proxy.size),
                        onSelect: { itemID in
                            boardStore.selectItem(itemID)
                        },
                        onClearSelection: {
                            boardStore.clearSelection()
                        },
                        onMove: { itemID, origin in
                            boardStore.updateItemPosition(
                                itemID,
                                to: origin,
                                constrainedTo: boardSize(from: proxy.size)
                            )
                        },
                        onDuplicate: { itemID in
                            boardStore.duplicateItem(
                                itemID,
                                constrainedTo: boardSize(from: proxy.size)
                            )
                        },
                        onDelete: { itemID in
                            boardStore.deleteItem(itemID)
                        }
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .zIndex(3)

                    BoardKeyboardView { event in
                        handleKeyDown(event, boardSize: boardSize(from: proxy.size))
                    }
                    .frame(width: 0, height: 0)
                    .zIndex(4)
                }
                .clipped()
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 22, x: 0, y: 18)
        .padding(1)
    }

    private func handleKeyDown(_ event: NSEvent, boardSize: BoardSize) -> Bool {
        if event.modifierFlags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "d" {
            return boardStore.duplicateSelectedItem(constrainedTo: boardSize) != nil
        }

        switch Int(event.keyCode) {
        case 51, 117:
            return boardStore.deleteSelectedItem()
        case 123:
            return moveSelectedItem(x: -keyboardMoveAmount(for: event), y: 0, boardSize: boardSize)
        case 124:
            return moveSelectedItem(x: keyboardMoveAmount(for: event), y: 0, boardSize: boardSize)
        case 125:
            return moveSelectedItem(x: 0, y: keyboardMoveAmount(for: event), boardSize: boardSize)
        case 126:
            return moveSelectedItem(x: 0, y: -keyboardMoveAmount(for: event), boardSize: boardSize)
        default:
            return false
        }
    }

    private func moveSelectedItem(x: Double, y: Double, boardSize: BoardSize) -> Bool {
        boardStore.moveSelectedItem(
            by: BoardPoint(x: x, y: y),
            constrainedTo: boardSize
        )
    }

    private func keyboardMoveAmount(for event: NSEvent) -> Double {
        event.modifierFlags.contains(.shift) ? 24 : 8
    }

    private func boardSize(from size: CGSize) -> BoardSize {
        BoardSize(width: size.width, height: size.height)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(boardStore.selectedBoard.name)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)

            Spacer()

            Text("\(boardStore.selectedBoard.items.count)")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

private struct BoardCanvasBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing = CGFloat(28)
            let color = Color.primary.opacity(0.055)

            for x in stride(from: CGFloat(0), through: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(color), lineWidth: 0.5)
            }

            for y in stride(from: CGFloat(0), through: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(color), lineWidth: 0.5)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor).opacity(0.74),
                    Color(nsColor: .controlBackgroundColor).opacity(0.58)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
