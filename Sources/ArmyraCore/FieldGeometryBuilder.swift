import Foundation

public struct FieldGeometry: Equatable, Sendable {
    public var boundary: [LineSegment]
    public var interiorLines: [LineSegment]
    public var circles: [CircleMarking]
    public var guidePath: [LineSegment]

    public init(
        boundary: [LineSegment],
        interiorLines: [LineSegment],
        circles: [CircleMarking],
        guidePath: [LineSegment]
    ) {
        self.boundary = boundary
        self.interiorLines = interiorLines
        self.circles = circles
        self.guidePath = guidePath
    }

    public func transformed(using transform: FieldTransform) -> FieldGeometry {
        FieldGeometry(
            boundary: boundary.map { $0.transformed(using: transform) },
            interiorLines: interiorLines.map { $0.transformed(using: transform) },
            circles: circles.map { $0.transformed(using: transform) },
            guidePath: guidePath.map { $0.transformed(using: transform) }
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

        var boundary = [
            LineSegment(start: topLeft, end: topRight),
            LineSegment(start: topRight, end: bottomRight),
            LineSegment(start: bottomRight, end: bottomLeft),
            LineSegment(start: bottomLeft, end: topLeft),
        ]

        var interior: [LineSegment] = []
        var circles: [CircleMarking] = []

        if markings.contains(.halfwayLine) {
            interior.append(
                LineSegment(
                    start: Point2D(x: 0, y: halfWidth),
                    end: Point2D(x: 0, y: -halfWidth)
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
            interior.append(contentsOf: mirroredBox(depth: depth, width: width, pitchHalfLength: halfLength))
        }

        if markings.contains(.goalArea),
           let depth = dimensions.goalAreaDepthMeters,
           let width = dimensions.goalAreaWidthMeters {
            interior.append(contentsOf: mirroredBox(depth: depth, width: width, pitchHalfLength: halfLength))
        }

        if markings.contains(.penaltySpot), let spotDistance = dimensions.penaltySpotDistanceMeters {
            circles.append(CircleMarking(center: Point2D(x: -halfLength + spotDistance, y: 0), radiusMeters: 0.15))
            circles.append(CircleMarking(center: Point2D(x: halfLength - spotDistance, y: 0), radiusMeters: 0.15))
        }

        boundary = boundary.filter { $0.start != $0.end }
        interior = interior.filter { $0.start != $0.end }

        return FieldGeometry(
            boundary: boundary,
            interiorLines: interior,
            circles: circles,
            guidePath: boundary + interior
        )
    }

    private static func mirroredBox(depth: Double, width: Double, pitchHalfLength: Double) -> [LineSegment] {
        let halfBoxWidth = width / 2
        let leftBoundaryX = -pitchHalfLength
        let rightBoundaryX = pitchHalfLength
        let leftInnerX = leftBoundaryX + depth
        let rightInnerX = rightBoundaryX - depth

        let leftBox = [
            LineSegment(start: Point2D(x: leftInnerX, y: halfBoxWidth), end: Point2D(x: leftInnerX, y: -halfBoxWidth)),
            LineSegment(start: Point2D(x: leftBoundaryX, y: halfBoxWidth), end: Point2D(x: leftInnerX, y: halfBoxWidth)),
            LineSegment(start: Point2D(x: leftBoundaryX, y: -halfBoxWidth), end: Point2D(x: leftInnerX, y: -halfBoxWidth)),
        ]

        let rightBox = [
            LineSegment(start: Point2D(x: rightInnerX, y: halfBoxWidth), end: Point2D(x: rightInnerX, y: -halfBoxWidth)),
            LineSegment(start: Point2D(x: rightInnerX, y: halfBoxWidth), end: Point2D(x: rightBoundaryX, y: halfBoxWidth)),
            LineSegment(start: Point2D(x: rightInnerX, y: -halfBoxWidth), end: Point2D(x: rightBoundaryX, y: -halfBoxWidth)),
        ]

        return leftBox + rightBox
    }
}