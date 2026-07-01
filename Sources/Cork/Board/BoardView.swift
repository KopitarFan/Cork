import CorkCore
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

                    ForEach(boardStore.selectedBoard.items) { item in
                        BoardCardView(item: item, boardSize: proxy.size) { origin in
                            boardStore.updateItemPosition(item.id, to: origin)
                        }
                    }
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
