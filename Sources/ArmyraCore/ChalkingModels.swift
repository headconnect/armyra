import Foundation

public enum TrackingConfidence: String, Codable, CaseIterable, Sendable {
    case good
    case warning
    case recover
}

public enum GuideSegmentKind: String, Codable, CaseIterable, Sendable {
    case boundary
    case interior
}

public struct GuideSegment: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var kind: GuideSegmentKind
    public var label: String
    public var segment: LineSegment

    public init(
        id: UUID = UUID(),
        kind: GuideSegmentKind,
        label: String,
        segment: LineSegment
    ) {
        self.id = id
        self.kind = kind
        self.label = label
        self.segment = segment
    }

    public func transformed(using transform: FieldTransform) -> GuideSegment {
        GuideSegment(
            id: id,
            kind: kind,
            label: label,
            segment: segment.transformed(using: transform)
        )
    }
}

public struct ChalkingSessionState: Equatable, Sendable {
    public var layoutID: UUID
    public var layoutName: String
    public var completedSegments: Int
    public var totalSegments: Int
    public var trackingConfidence: TrackingConfidence
    public var recommendedHint: String
    public var guideSegments: [GuideSegment]

    public init(
        layoutID: UUID,
        layoutName: String,
        completedSegments: Int,
        totalSegments: Int,
        trackingConfidence: TrackingConfidence,
        recommendedHint: String,
        guideSegments: [GuideSegment]
    ) {
        self.layoutID = layoutID
        self.layoutName = layoutName
        self.completedSegments = completedSegments
        self.totalSegments = totalSegments
        self.trackingConfidence = trackingConfidence
        self.recommendedHint = recommendedHint
        self.guideSegments = guideSegments
    }

    public var progressFraction: Double {
        guard totalSegments > 0 else { return 0 }
        return Double(completedSegments) / Double(totalSegments)
    }

    public var currentSegment: GuideSegment? {
        guard completedSegments < guideSegments.count else { return nil }
        return guideSegments[completedSegments]
    }

    public var upcomingSegments: [GuideSegment] {
        guard completedSegments < guideSegments.count else { return [] }
        let nextIndex = min(completedSegments + 1, guideSegments.count)
        return Array(guideSegments[nextIndex...].prefix(3))
    }
}
