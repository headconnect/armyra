import Foundation

public enum RelocalizationState: String, Codable, CaseIterable, Sendable {
    case unavailable
    case scanning
    case localized
    case limited
}

public enum ARSessionMode: String, Codable, CaseIterable, Sendable {
    case idle
    case planning
    case chalking
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

public struct ARSessionDiagnostics: Equatable, Sendable {
    public var mode: ARSessionMode
    public var relocalizationState: RelocalizationState
    public var readinessScore: Double
    public var hasLocalAsset: Bool
    public var payloadSizeBytes: Int
    public var activeHint: String
    public var lastErrorDescription: String?

    public init(
        mode: ARSessionMode,
        relocalizationState: RelocalizationState,
        readinessScore: Double,
        hasLocalAsset: Bool,
        payloadSizeBytes: Int,
        activeHint: String,
        lastErrorDescription: String?
    ) {
        self.mode = mode
        self.relocalizationState = relocalizationState
        self.readinessScore = readinessScore
        self.hasLocalAsset = hasLocalAsset
        self.payloadSizeBytes = payloadSizeBytes
        self.activeHint = activeHint
        self.lastErrorDescription = lastErrorDescription
    }
}

public enum ARDiagnosticsEventKind: String, Codable, CaseIterable, Sendable {
    case started
    case refreshed
    case assetSaved
    case driftSimulated
    case stopped
    case error
}

public struct ARDiagnosticsEvent: Equatable, Identifiable, Sendable {
    public var id: UUID
    public var timestamp: Date
    public var kind: ARDiagnosticsEventKind
    public var diagnostics: ARSessionDiagnostics

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        kind: ARDiagnosticsEventKind,
        diagnostics: ARSessionDiagnostics
    ) {
        self.id = id
        self.timestamp = timestamp
        self.kind = kind
        self.diagnostics = diagnostics
    }
}
