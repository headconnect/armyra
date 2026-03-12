import Foundation

public enum RelocalizationState: String, Codable, CaseIterable, Sendable {
    case unavailable
    case scanning
    case localized
    case limited
}

public struct VenueTrackingSnapshot: Equatable, Sendable {
    public var venueScanID: UUID
    public var relocalizationState: RelocalizationState
    public var readinessScore: Double
    public var activeHint: String

    public init(
        venueScanID: UUID,
        relocalizationState: RelocalizationState,
        readinessScore: Double,
        activeHint: String
    ) {
        self.venueScanID = venueScanID
        self.relocalizationState = relocalizationState
        self.readinessScore = readinessScore
        self.activeHint = activeHint
    }
}

public struct VenueTrackingAssetRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var venueScanID: UUID
    public var createdAt: Date
    public var localStorageKey: String
    public var readinessScore: Double

    public init(
        id: UUID = UUID(),
        venueScanID: UUID,
        createdAt: Date = Date(),
        localStorageKey: String,
        readinessScore: Double
    ) {
        self.id = id
        self.venueScanID = venueScanID
        self.createdAt = createdAt
        self.localStorageKey = localStorageKey
        self.readinessScore = readinessScore
    }
}
