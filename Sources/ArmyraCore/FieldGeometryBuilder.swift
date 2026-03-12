import Foundation

public struct FieldGeometry: Equatable, Sendable {
    public var boundary: [LineSegment]
    public var interiorLines: [LineSegment]
    public var circles: [CircleMarking]
    public var guidePath: [LineSegment]
    public var guideSegments: [GuideSegment]

    public init(
        boundary: [LineSegment],
        interiorLines: [LineSegment],
        circles: [CircleMarking],
        guidePath: [LineSegment],
        guideSegments: [GuideSegment]
    ) {
        self.boundary = boundary
        self.interiorLines = interiorLines
        self.circles = circles
        self.guidePath = guidePath
        self.guideSegments = guideSegments
    }

    public func transformed(using transform: FieldTransform) -> FieldGeometry {
        FieldGeometry(
            boundary: boundary.map { $0.transformed(using: transform) },
            interiorLines: interiorLines.map { $0.transformed(using: transform) },
            circles: circles.map { $0.transformed(using: transform) },
            guidePath: guidePath.map { $0.transformed(using: transform) },
            guideSegments: guideSegments.map { $0.transformed(using: transform) }
        )
    }
}

public enum FieldGeometryBuilder {
    public static func build(for layout: FieldLayout) -> FieldGeometry {
        let local = buildLocal(dimensions: layout.dimensions, markings: layout.enabledMarkings)
        return local.transformed(using: layout.transform)
    }

    public static func buildLocal(
        dimensions: PitchDimensions,
        markings: Set<LineMarking>
    ) -> FieldGeometry {
        let halfLength = dimensions.lengthMeters / 2
        let halfWidth = dimensions.widthMeters / 2

        let topLeft = Point2D(x: -halfLength, y: halfWidth)
        let topRight = Point2D(x: halfLength, y: halfWidth)
        let bottomRight = Point2D(x: halfLength, y: -halfWidth)
        let bottomLeft = Point2D(x: -halfLength, y: -halfWidth)

        var boundarySegments = [
            GuideSegment(kind: .boundary, label: "Top touchline", segment: LineSegment(start: topLeft, end: topRight)),
            GuideSegment(kind: .boundary, label: "Right goal line", segment: LineSegment(start: topRight, end: bottomRight)),
            GuideSegment(kind: .boundary, label: "Bottom touchline", segment: LineSegment(start: bottomRight, end: bottomLeft)),
            GuideSegment(kind: .boundary, label: "Left goal line", segment: LineSegment(start: bottomLeft, end: topLeft)),
        ]

        var interiorSegments: [GuideSegment] = []
        var circles: [CircleMarking] = []

        if markings.contains(.halfwayLine) {
            interiorSegments.append(
                GuideSegment(
                    kind: .interior,
                    label: "Halfway line",
                    segment: LineSegment(
                    start: Point2D(x: 0, y: halfWidth),
                    end: Point2D(x: 0, y: -halfWidth)
                    )
                )
            )
        }

        if markings.contains(.centerCircle), let radius = dimensions.centerCircleRadiusMeters {
            circles.append(CircleMarking(center: Point2D(x: 0, y: 0), radiusMeters: radius))
        }

        if markings.contains(.centerSpot) {
            circles.append(CircleMarking(center: Point2D(x: 0, y: 0), radiusMeters: 0.15))
        }

        if markings.contains(.penaltyArea),
           let depth = dimensions.penaltyAreaDepthMeters,
           let width = dimensions.penaltyAreaWidthMeters {
            interiorSegments.append(contentsOf: mirroredBox(
                depth: depth,
                width: width,
                pitchHalfLength: halfLength,
                labelPrefix: "Penalty area"
            ))
        }

        if markings.contains(.goalArea),
           let depth = dimensions.goalAreaDepthMeters,
           let width = dimensions.goalAreaWidthMeters {
            interiorSegments.append(contentsOf: mirroredBox(
                depth: depth,
                width: width,
                pitchHalfLength: halfLength,
                labelPrefix: "Goal area"
            ))
        }

        if markings.contains(.penaltySpot), let spotDistance = dimensions.penaltySpotDistanceMeters {
            circles.append(CircleMarking(center: Point2D(x: -halfLength + spotDistance, y: 0), radiusMeters: 0.15))
            circles.append(CircleMarking(center: Point2D(x: halfLength - spotDistance, y: 0), radiusMeters: 0.15))
        }

        boundarySegments = boundarySegments.filter { $0.segment.start != $0.segment.end }
        interiorSegments = interiorSegments.filter { $0.segment.start != $0.segment.end }
        let guideSegments = boundarySegments + interiorSegments

        return FieldGeometry(
            boundary: boundarySegments.map(\.segment),
            interiorLines: interiorSegments.map(\.segment),
            circles: circles,
            guidePath: guideSegments.map(\.segment),
            guideSegments: guideSegments
        )
    }

    private static func mirroredBox(
        depth: Double,
        width: Double,
        pitchHalfLength: Double,
        labelPrefix: String
    ) -> [GuideSegment] {
        let halfBoxWidth = width / 2
        let leftBoundaryX = -pitchHalfLength
        let rightBoundaryX = pitchHalfLength
        let leftInnerX = leftBoundaryX + depth
        let rightInnerX = rightBoundaryX - depth

        let leftBox = [
            GuideSegment(kind: .interior, label: "\(labelPrefix) left spine", segment: LineSegment(start: Point2D(x: leftInnerX, y: halfBoxWidth), end: Point2D(x: leftInnerX, y: -halfBoxWidth))),
            GuideSegment(kind: .interior, label: "\(labelPrefix) left top", segment: LineSegment(start: Point2D(x: leftBoundaryX, y: halfBoxWidth), end: Point2D(x: leftInnerX, y: halfBoxWidth))),
            GuideSegment(kind: .interior, label: "\(labelPrefix) left bottom", segment: LineSegment(start: Point2D(x: leftBoundaryX, y: -halfBoxWidth), end: Point2D(x: leftInnerX, y: -halfBoxWidth))),
        ]

        let rightBox = [
            GuideSegment(kind: .interior, label: "\(labelPrefix) right spine", segment: LineSegment(start: Point2D(x: rightInnerX, y: halfBoxWidth), end: Point2D(x: rightInnerX, y: -halfBoxWidth))),
            GuideSegment(kind: .interior, label: "\(labelPrefix) right top", segment: LineSegment(start: Point2D(x: rightInnerX, y: halfBoxWidth), end: Point2D(x: rightBoundaryX, y: halfBoxWidth))),
            GuideSegment(kind: .interior, label: "\(labelPrefix) right bottom", segment: LineSegment(start: Point2D(x: rightInnerX, y: -halfBoxWidth), end: Point2D(x: rightBoundaryX, y: -halfBoxWidth))),
        ]

        return leftBox + rightBox
    }
}
