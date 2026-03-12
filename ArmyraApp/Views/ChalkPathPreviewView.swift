import SwiftUI
import ArmyraCore

struct ChalkPathPreviewView: View {
    let guideSegments: [GuideSegment]
    let activeSegmentID: UUID?
    let completedSegmentIDs: Set<UUID>
    let startPoint: Point2D?
    let recoveryPoint: Point2D?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let points = guideSegments.flatMap { [$0.segment.start, $0.segment.end] }
            let extent = boundingBox(for: points)
            let scale = min(
                size.width / max(extent.width + 20, 1),
                size.height / max(extent.height + 20, 1)
            )

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.18), .mint.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                ForEach(guideSegments) { guideSegment in
                    let start = scaledPoint(guideSegment.segment.start, extent: extent, scale: scale, canvasSize: size)
                    let end = scaledPoint(guideSegment.segment.end, extent: extent, scale: scale, canvasSize: size)
                    let isCompleted = completedSegmentIDs.contains(guideSegment.id)
                    let isActive = guideSegment.id == activeSegmentID

                    Path { path in
                        path.move(to: start)
                        path.addLine(to: end)
                    }
                    .stroke(
                        strokeColor(isCompleted: isCompleted, isActive: isActive, kind: guideSegment.kind),
                        style: StrokeStyle(lineWidth: isActive ? 6 : 4, lineCap: .round)
                    )
                }

                if let startPoint {
                    marker("S", at: scaledPoint(startPoint, extent: extent, scale: scale, canvasSize: size), color: .blue)
                }

                if let recoveryPoint {
                    marker("R", at: scaledPoint(recoveryPoint, extent: extent, scale: scale, canvasSize: size), color: .red)
                }
            }
        }
    }

    private func marker(_ label: String, at point: CGPoint, color: Color) -> some View {
        Text(label)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(color, in: Circle())
            .position(point)
    }

    private func strokeColor(isCompleted: Bool, isActive: Bool, kind: GuideSegmentKind) -> Color {
        if isActive {
            return .orange
        }
        if isCompleted {
            return .green.opacity(0.5)
        }

        switch kind {
        case .boundary:
            return .white.opacity(0.9)
        case .interior:
            return .yellow.opacity(0.8)
        }
    }

    private func boundingBox(for points: [Point2D]) -> FieldBoundingBox {
        guard let first = points.first else {
            return FieldBoundingBox(minX: -10, maxX: 10, minY: -10, maxY: 10)
        }

        return points.dropFirst().reduce(
            FieldBoundingBox(minX: first.x, maxX: first.x, minY: first.y, maxY: first.y)
        ) { partial, point in
            FieldBoundingBox(
                minX: min(partial.minX, point.x),
                maxX: max(partial.maxX, point.x),
                minY: min(partial.minY, point.y),
                maxY: max(partial.maxY, point.y)
            )
        }
    }

    private func scaledPoint(
        _ point: Point2D,
        extent: FieldBoundingBox,
        scale: Double,
        canvasSize: CGSize
    ) -> CGPoint {
        CGPoint(
            x: ((point.x - extent.minX) * scale) + 10 + ((canvasSize.width - ((extent.width * scale) + 20)) / 2),
            y: ((extent.maxY - point.y) * scale) + 10 + ((canvasSize.height - ((extent.height * scale) + 20)) / 2)
        )
    }
}
