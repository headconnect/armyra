import SwiftUI
import ArmyraCore

struct PlanningPreviewView: View {
    let layouts: [FieldLayout]
    let selectedLayoutID: UUID?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let boxes = layouts.map { ($0, FieldLayoutAnalysis.boundingBox(for: $0)) }
            let extent = FieldBoundingBox.union(boxes.map(\.1)) ?? FieldBoundingBox(minX: -10, maxX: 10, minY: -10, maxY: 10)
            let scale = min(
                size.width / max(extent.width + 20, 1),
                size.height / max(extent.height + 20, 1)
            )

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.18), .mint.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                ForEach(boxes, id: \.0.id) { layout, box in
                    let center = scaledPoint(
                        x: layout.transform.translation.dx,
                        y: layout.transform.translation.dy,
                        extent: extent,
                        scale: scale,
                        canvasSize: size
                    )
                    let fieldWidth = layout.dimensions.lengthMeters * scale
                    let fieldHeight = layout.dimensions.widthMeters * scale
                    let isSelected = layout.id == selectedLayoutID

                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .stroke(isSelected ? .blue : .primary.opacity(0.65), lineWidth: isSelected ? 3 : 2)
                            .background(
                                Rectangle()
                                    .fill(isSelected ? .blue.opacity(0.14) : .white.opacity(0.08))
                            )
                            .frame(width: fieldWidth, height: fieldHeight)
                            .rotationEffect(.radians(layout.transform.rotationRadians))

                        Text(layout.name)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                            .offset(x: 6, y: 6)
                    }
                    .position(center)
                }
            }
        }
    }

    private func scaledPoint(
        x: Double,
        y: Double,
        extent: FieldBoundingBox,
        scale: Double,
        canvasSize: CGSize
    ) -> CGPoint {
        CGPoint(
            x: ((x - extent.minX) * scale) + 10 + ((canvasSize.width - ((extent.width * scale) + 20)) / 2),
            y: ((extent.maxY - y) * scale) + 10 + ((canvasSize.height - ((extent.height * scale) + 20)) / 2)
        )
    }
}
