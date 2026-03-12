import Foundation

public struct FieldBoundingBox: Equatable, Sendable {
    public var minX: Double
    public var maxX: Double
    public var minY: Double
    public var maxY: Double

    public init(minX: Double, maxX: Double, minY: Double, maxY: Double) {
        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
    }

    public var width: Double { maxX - minX }
    public var height: Double { maxY - minY }

    public func intersects(_ other: FieldBoundingBox) -> Bool {
        minX < other.maxX &&
        maxX > other.minX &&
        minY < other.maxY &&
        maxY > other.minY
    }

    public static func union(_ boxes: [FieldBoundingBox]) -> FieldBoundingBox? {
        guard let first = boxes.first else { return nil }

        return boxes.dropFirst().reduce(first) { partial, box in
            FieldBoundingBox(
                minX: min(partial.minX, box.minX),
                maxX: max(partial.maxX, box.maxX),
                minY: min(partial.minY, box.minY),
                maxY: max(partial.maxY, box.maxY)
            )
        }
    }
}

public struct LayoutOverlap: Equatable, Sendable {
    public var firstLayoutID: UUID
    public var secondLayoutID: UUID

    public init(firstLayoutID: UUID, secondLayoutID: UUID) {
        self.firstLayoutID = firstLayoutID
        self.secondLayoutID = secondLayoutID
    }
}

public struct LayoutSpacingIssue: Equatable, Sendable {
    public var firstLayoutID: UUID
    public var secondLayoutID: UUID
    public var gapMeters: Double

    public init(firstLayoutID: UUID, secondLayoutID: UUID, gapMeters: Double) {
        self.firstLayoutID = firstLayoutID
        self.secondLayoutID = secondLayoutID
        self.gapMeters = gapMeters
    }
}

public enum FieldLayoutAnalysis {
    public static func boundingBox(for layout: FieldLayout) -> FieldBoundingBox {
        let geometry = FieldGeometryBuilder.build(for: layout)
        let points = geometry.boundary.flatMap { [$0.start, $0.end] }

        guard let first = points.first else {
            return FieldBoundingBox(minX: 0, maxX: 0, minY: 0, maxY: 0)
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

    public static func overlaps(in layouts: [FieldLayout]) -> [LayoutOverlap] {
        let boxes = layouts.map { ($0.id, boundingBox(for: $0)) }
        var overlaps: [LayoutOverlap] = []

        for firstIndex in boxes.indices {
            for secondIndex in boxes.indices where secondIndex > firstIndex {
                let first = boxes[firstIndex]
                let second = boxes[secondIndex]

                if first.1.intersects(second.1) {
                    overlaps.append(
                        LayoutOverlap(firstLayoutID: first.0, secondLayoutID: second.0)
                    )
                }
            }
        }

        return overlaps
    }

    public static func tightSpacing(in layouts: [FieldLayout], minimumGap: Double) -> [LayoutSpacingIssue] {
        let boxes = layouts.map { ($0.id, boundingBox(for: $0)) }
        var issues: [LayoutSpacingIssue] = []

        for firstIndex in boxes.indices {
            for secondIndex in boxes.indices where secondIndex > firstIndex {
                let first = boxes[firstIndex]
                let second = boxes[secondIndex]

                if first.1.intersects(second.1) {
                    continue
                }

                let gap = gapBetween(first.1, second.1)
                if gap < minimumGap {
                    issues.append(
                        LayoutSpacingIssue(
                            firstLayoutID: first.0,
                            secondLayoutID: second.0,
                            gapMeters: gap
                        )
                    )
                }
            }
        }

        return issues
    }

    private static func gapBetween(_ first: FieldBoundingBox, _ second: FieldBoundingBox) -> Double {
        let horizontalGap = max(0, max(second.minX - first.maxX, first.minX - second.maxX))
        let verticalGap = max(0, max(second.minY - first.maxY, first.minY - second.maxY))
        return hypot(horizontalGap, verticalGap)
    }
}
