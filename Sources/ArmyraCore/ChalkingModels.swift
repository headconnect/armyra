import Foundation

public enum TrackingConfidence: String, Codable, CaseIterable, Sendable {
    case good
    case warning
    case recover
}

public struct ChalkingSessionState: Equatable, Sendable {
    public var layoutID: UUID
    public var layoutName: String
    public var completedSegments: Int
    public var totalSegments: Int
    public var trackingConfidence: TrackingConfidence
    public var recommendedHint: String

    public init(
        layoutID: UUID,
        layoutName: String,
        completedSegments: Int,
        totalSegments: Int,
        trackingConfidence: TrackingConfidence,
        recommendedHint: String
    ) {
        self.layoutID = layoutID
        self.layoutName = layoutName
        self.completedSegments = completedSegments
        self.totalSegments = totalSegments
        self.trackingConfidence = trackingConfidence
        self.recommendedHint = recommendedHint
    }

    public var progressFraction: Double {
        guard totalSegments > 0 else { return 0 }
        return Double(completedSegments) / Double(totalSegments)
    }
}
