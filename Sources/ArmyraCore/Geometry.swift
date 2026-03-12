import Foundation

public struct Point2D: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public func rotated(by radians: Double) -> Point2D {
        let cosine = cos(radians)
        let sine = sin(radians)
        return Point2D(
            x: (x * cosine) - (y * sine),
            y: (x * sine) + (y * cosine)
        )
    }

    public func translated(by offset: Vector2D) -> Point2D {
        Point2D(x: x + offset.dx, y: y + offset.dy)
    }
}

public struct Vector2D: Codable, Equatable, Sendable {
    public var dx: Double
    public var dy: Double

    public init(dx: Double, dy: Double) {
        self.dx = dx
        self.dy = dy
    }
}

public struct LineSegment: Codable, Equatable, Sendable {
    public var start: Point2D
    public var end: Point2D

    public init(start: Point2D, end: Point2D) {
        self.start = start
        self.end = end
    }

    public func transformed(using transform: FieldTransform) -> LineSegment {
        LineSegment(
            start: transform.apply(to: start),
            end: transform.apply(to: end)
        )
    }
}

public struct CircleMarking: Codable, Equatable, Sendable {
    public var center: Point2D
    public var radiusMeters: Double

    public init(center: Point2D, radiusMeters: Double) {
        self.center = center
        self.radiusMeters = radiusMeters
    }

    public func transformed(using transform: FieldTransform) -> CircleMarking {
        CircleMarking(
            center: transform.apply(to: center),
            radiusMeters: radiusMeters
        )
    }
}