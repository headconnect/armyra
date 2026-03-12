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
    public var landmarks: [VenueLandmark]
    public var coveredSides: Int
    public var preferredStartEdge: String?
    public var preferredRecoveryEdge: String?
    public var readinessScore: Double
    public var phase: VenueScanPhase
    public var recommendedHint: String

    public init(
        venueName: String,
        capturedLandmarks: [String],
        landmarks: [VenueLandmark] = [],
        coveredSides: Int,
        preferredStartEdge: String? = nil,
        preferredRecoveryEdge: String? = nil,
        readinessScore: Double,
        phase: VenueScanPhase,
        recommendedHint: String
    ) {
        self.venueName = venueName
        self.capturedLandmarks = capturedLandmarks
        self.landmarks = landmarks
        self.coveredSides = coveredSides
        self.preferredStartEdge = preferredStartEdge
        self.preferredRecoveryEdge = preferredRecoveryEdge
        self.readinessScore = readinessScore
        self.phase = phase
        self.recommendedHint = recommendedHint
    }
}
