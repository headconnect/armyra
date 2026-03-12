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

public enum LayoutLaneAxis: String, Codable, Equatable, Sendable {
    case horizontal
    case vertical
}

public struct LayoutLaneIssue: Equatable, Sendable {
    public var firstLayoutID: UUID
    public var secondLayoutID: UUID
    public var laneWidthMeters: Double
    public var axis: LayoutLaneAxis

    public init(
        firstLayoutID: UUID,
        secondLayoutID: UUID,
        laneWidthMeters: Double,
        axis: LayoutLaneAxis
    ) {
        self.firstLayoutID = firstLayoutID
        self.secondLayoutID = secondLayoutID
        self.laneWidthMeters = laneWidthMeters
        self.axis = axis
    }
}

public enum SetupCorridorAxis: String, Codable, Equatable, Sendable {
    case horizontal
    case vertical
}

public enum VenueEdgeOrientation: String, Codable, Equatable, Sendable {
    case horizontalBoundary
    case verticalBoundary
}

public struct VenueSetupCorridorSummary: Equatable, Sendable {
    public var widestHorizontalBandMeters: Double
    public var widestVerticalBandMeters: Double
    public var preferredAxis: SetupCorridorAxis

    public init(
        widestHorizontalBandMeters: Double,
        widestVerticalBandMeters: Double,
        preferredAxis: SetupCorridorAxis
    ) {
        self.widestHorizontalBandMeters = widestHorizontalBandMeters
        self.widestVerticalBandMeters = widestVerticalBandMeters
        self.preferredAxis = preferredAxis
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

    public static func practicalLaneIssues(
        in layouts: [FieldLayout],
        minimumLaneWidth: Double
    ) -> [LayoutLaneIssue] {
        let boxes = layouts.map { ($0.id, boundingBox(for: $0)) }
        var issues: [LayoutLaneIssue] = []

        for firstIndex in boxes.indices {
            for secondIndex in boxes.indices where secondIndex > firstIndex {
                let first = boxes[firstIndex]
                let second = boxes[secondIndex]

                if first.1.intersects(second.1) {
                    continue
                }

                if overlaps(on: \.minY, \.maxY, first.1, second.1) {
                    let horizontalGap = max(0, max(second.1.minX - first.1.maxX, first.1.minX - second.1.maxX))
                    if horizontalGap < minimumLaneWidth {
                        issues.append(
                            LayoutLaneIssue(
                                firstLayoutID: first.0,
                                secondLayoutID: second.0,
                                laneWidthMeters: horizontalGap,
                                axis: .horizontal
                            )
                        )
                    }
                }

                if overlaps(on: \.minX, \.maxX, first.1, second.1) {
                    let verticalGap = max(0, max(second.1.minY - first.1.maxY, first.1.minY - second.1.maxY))
                    if verticalGap < minimumLaneWidth {
                        issues.append(
                            LayoutLaneIssue(
                                firstLayoutID: first.0,
                                secondLayoutID: second.0,
                                laneWidthMeters: verticalGap,
                                axis: .vertical
                            )
                        )
                    }
                }
            }
        }

        return issues
    }

    public static func setupCorridorSummary(in layouts: [FieldLayout]) -> VenueSetupCorridorSummary? {
        let boxes = layouts.map { boundingBox(for: $0) }
        guard let extent = FieldBoundingBox.union(boxes) else { return nil }

        let widestVerticalBand = widestInternalGap(
            in: boxes.map { ($0.minX, $0.maxX) },
            lowerBound: extent.minX,
            upperBound: extent.maxX
        )
        let widestHorizontalBand = widestInternalGap(
            in: boxes.map { ($0.minY, $0.maxY) },
            lowerBound: extent.minY,
            upperBound: extent.maxY
        )

        let preferredAxis: SetupCorridorAxis = widestVerticalBand >= widestHorizontalBand ? .vertical : .horizontal

        return VenueSetupCorridorSummary(
            widestHorizontalBandMeters: widestHorizontalBand,
            widestVerticalBandMeters: widestVerticalBand,
            preferredAxis: preferredAxis
        )
    }

    public static func inferEdgeOrientation(from label: String) -> VenueEdgeOrientation? {
        let normalized = label.lowercased()

        let horizontalBoundaryKeywords = [
            "north", "south", "goal", "end line", "endline", "clubhouse", "car park", "carpark"
        ]
        if horizontalBoundaryKeywords.contains(where: normalized.contains) {
            return .horizontalBoundary
        }

        let verticalBoundaryKeywords = [
            "east", "west", "touchline", "sideline", "side", "fence", "bench"
        ]
        if verticalBoundaryKeywords.contains(where: normalized.contains) {
            return .verticalBoundary
        }

        return nil
    }

    private static func gapBetween(_ first: FieldBoundingBox, _ second: FieldBoundingBox) -> Double {
        let horizontalGap = max(0, max(second.minX - first.maxX, first.minX - second.maxX))
        let verticalGap = max(0, max(second.minY - first.maxY, first.minY - second.maxY))
        return hypot(horizontalGap, verticalGap)
    }

    private static func overlaps(
        on minKeyPath: KeyPath<FieldBoundingBox, Double>,
        _ maxKeyPath: KeyPath<FieldBoundingBox, Double>,
        _ first: FieldBoundingBox,
        _ second: FieldBoundingBox
    ) -> Bool {
        first[keyPath: minKeyPath] < second[keyPath: maxKeyPath] &&
        first[keyPath: maxKeyPath] > second[keyPath: minKeyPath]
    }

    private static func widestInternalGap(
        in intervals: [(Double, Double)],
        lowerBound: Double,
        upperBound: Double
    ) -> Double {
        guard intervals.isEmpty == false else { return upperBound - lowerBound }

        let sorted = intervals.sorted { lhs, rhs in
            if lhs.0 == rhs.0 {
                return lhs.1 < rhs.1
            }
            return lhs.0 < rhs.0
        }

        var merged: [(Double, Double)] = []
        for interval in sorted {
            if let last = merged.last, interval.0 <= last.1 {
                merged[merged.count - 1] = (last.0, max(last.1, interval.1))
            } else {
                merged.append(interval)
            }
        }

        var widestGap = 0.0
        var cursor = lowerBound

        for interval in merged {
            widestGap = max(widestGap, interval.0 - cursor)
            cursor = max(cursor, interval.1)
        }

        widestGap = max(widestGap, upperBound - cursor)
        return max(widestGap, 0)
    }
}
