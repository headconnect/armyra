import Foundation

public enum VenueScanPhase: String, Codable, CaseIterable, Sendable {
    case scanning
    case ready
    case localized
    case recovery
}

public struct VenueScanSessionState: Equatable, Sendable {
    public var venueName: String
    public var capturedLandmarks: [String]
    public var coveredSides: Int
    public var readinessScore: Double
    public var phase: VenueScanPhase
    public var recommendedHint: String

    public init(
        venueName: String,
        capturedLandmarks: [String],
        coveredSides: Int,
        readinessScore: Double,
        phase: VenueScanPhase,
        recommendedHint: String
    ) {
        self.venueName = venueName
        self.capturedLandmarks = capturedLandmarks
        self.coveredSides = coveredSides
        self.readinessScore = readinessScore
        self.phase = phase
        self.recommendedHint = recommendedHint
    }
}
