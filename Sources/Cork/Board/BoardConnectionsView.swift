import CorkCore
import SwiftUI

struct BoardConnectionPreview: Equatable {
    let id: UUID
    let sourceItemID: BoardItem.ID
    let style: BoardConnectionStyle
    var targetPoint: BoardPoint
}

struct BoardConnectionsView: View {
    let items: [BoardItem]
    let connections: [BoardConnection]
    let preview: BoardConnectionPreview?

    var body: some View {
        Canvas { context, _ in
            let itemFrames = Dictionary(uniqueKeysWithValues: items.map { item in
                (item.id, item.frame.cgRect)
            })

            for connection in connections {
                guard let sourceFrame = itemFrames[connection.sourceItemID],
                      let targetFrame = itemFrames[connection.targetItemID]
                else {
                    continue
                }

                let sourceCenter = CGPoint(x: sourceFrame.midX, y: sourceFrame.midY)
                let targetCenter = CGPoint(x: targetFrame.midX, y: targetFrame.midY)
                let start = edgePoint(in: sourceFrame, toward: targetCenter)
                let end = edgePoint(in: targetFrame, toward: sourceCenter)

                switch connection.style {
                case .line:
                    drawLine(from: start, to: end, in: &context)
                case .string:
                    drawString(
                        curveDirectionIsPositive: connection.curveDirectionIsPositive,
                        from: start,
                        to: end,
                        in: &context
                    )
                }
            }

            if let preview,
               let sourceFrame = itemFrames[preview.sourceItemID] {
                let target = CGPoint(x: preview.targetPoint.x, y: preview.targetPoint.y)
                let start = edgePoint(in: sourceFrame, toward: target)

                switch preview.style {
                case .line:
                    drawLine(from: start, to: target, in: &context)
                case .string:
                    drawString(
                        curveDirectionIsPositive: preview.curveDirectionIsPositive,
                        from: start,
                        to: target,
                        in: &context
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawLine(
        from start: CGPoint,
        to end: CGPoint,
        in context: inout GraphicsContext
    ) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)

        var shadowContext = context
        shadowContext.addFilter(.shadow(color: .black.opacity(0.22), radius: 2, x: 0, y: 1))
        shadowContext.stroke(
            path,
            with: .color(Color(red: 0.28, green: 0.34, blue: 0.38).opacity(0.78)),
            style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
        )
        drawPin(at: start, color: Color(red: 0.28, green: 0.34, blue: 0.38), in: &context)
        drawPin(at: end, color: Color(red: 0.28, green: 0.34, blue: 0.38), in: &context)
    }

    private func drawString(
        curveDirectionIsPositive: Bool,
        from start: CGPoint,
        to end: CGPoint,
        in context: inout GraphicsContext
    ) {
        let deltaX = end.x - start.x
        let deltaY = end.y - start.y
        let distance = max(1, hypot(deltaX, deltaY))
        let direction = CGPoint(x: deltaX / distance, y: deltaY / distance)
        let normalSign: CGFloat = curveDirectionIsPositive ? 1 : -1
        let normal = CGPoint(x: -direction.y * normalSign, y: direction.x * normalSign)
        let curveAmount = min(38, max(12, distance * 0.08))
        let firstControl = CGPoint(
            x: start.x + (deltaX * 0.33) + (normal.x * curveAmount),
            y: start.y + (deltaY * 0.33) + (normal.y * curveAmount)
        )
        let secondControl = CGPoint(
            x: start.x + (deltaX * 0.66) + (normal.x * curveAmount),
            y: start.y + (deltaY * 0.66) + (normal.y * curveAmount)
        )

        var path = Path()
        path.move(to: start)
        path.addCurve(to: end, control1: firstControl, control2: secondControl)

        var shadowContext = context
        shadowContext.addFilter(.shadow(color: .black.opacity(0.32), radius: 2.5, x: 0, y: 1.5))
        shadowContext.stroke(
            path,
            with: .color(Color(red: 0.30, green: 0.02, blue: 0.03).opacity(0.82)),
            style: StrokeStyle(lineWidth: 4.2, lineCap: .round)
        )
        context.stroke(
            path,
            with: .color(Color(red: 0.72, green: 0.08, blue: 0.10)),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
        )
        context.stroke(
            path,
            with: .color(.white.opacity(0.16)),
            style: StrokeStyle(lineWidth: 0.7, lineCap: .round)
        )

        let pinColor = Color(red: 0.66, green: 0.05, blue: 0.07)
        drawPin(at: start, color: pinColor, in: &context)
        drawPin(at: end, color: pinColor, in: &context)
    }

    private func drawPin(
        at point: CGPoint,
        color: Color,
        in context: inout GraphicsContext
    ) {
        let pinRect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
        let pinPath = Path(ellipseIn: pinRect)

        context.fill(pinPath, with: .color(color))
        context.stroke(pinPath, with: .color(.white.opacity(0.68)), lineWidth: 1)
    }

    private func edgePoint(in rect: CGRect, toward target: CGPoint) -> CGPoint {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let deltaX = target.x - center.x
        let deltaY = target.y - center.y

        guard deltaX != 0 || deltaY != 0 else {
            return center
        }

        let horizontalScale = deltaX == 0 ? CGFloat.greatestFiniteMagnitude : (rect.width / 2) / abs(deltaX)
        let verticalScale = deltaY == 0 ? CGFloat.greatestFiniteMagnitude : (rect.height / 2) / abs(deltaY)
        let scale = min(horizontalScale, verticalScale)

        return CGPoint(
            x: center.x + (deltaX * scale),
            y: center.y + (deltaY * scale)
        )
    }
}

private extension BoardRect {
    var cgRect: CGRect {
        CGRect(
            x: origin.x,
            y: origin.y,
            width: size.width,
            height: size.height
        )
    }
}

private extension BoardConnection {
    var curveDirectionIsPositive: Bool {
        id.uuidString.utf8.reduce(0) { $0 + Int($1) }.isMultiple(of: 2)
    }
}

private extension BoardConnectionPreview {
    var curveDirectionIsPositive: Bool {
        id.uuidString.utf8.reduce(0) { $0 + Int($1) }.isMultiple(of: 2)
    }
}
