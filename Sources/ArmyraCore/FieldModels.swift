import Foundation

public enum PitchSize: String, Codable, CaseIterable, Sendable {
    case fiveAside
    case sevenAside
    case nineAside
    case elevenAside
}

public enum LineMarking: String, Codable, CaseIterable, Sendable {
    case halfwayLine
    case centerCircle
    case centerSpot
    case penaltyArea
    case goalArea
    case penaltySpot
}

public enum PlacementLockMode: Codable, Equatable, Sendable {
    case center
    case corner(Corner)

    public enum Corner: String, Codable, CaseIterable, Sendable {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
}

public enum LandmarkRole: String, Codable, CaseIterable, Sendable {
    case general
    case startCandidate
    case recoveryCandidate
}

public struct VenueLandmark: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var label: String
    public var role: LandmarkRole

    public init(id: UUID = UUID(), label: String, role: LandmarkRole = .general) {
        self.id = id
        self.label = label
        self.role = role
    }
}

public struct PitchDimensions: Codable, Equatable, Sendable {
    public var lengthMeters: Double
    public var widthMeters: Double
    public var centerCircleRadiusMeters: Double?
    public var penaltyAreaDepthMeters: Double?
    public var penaltyAreaWidthMeters: Double?
    public var goalAreaDepthMeters: Double?
    public var goalAreaWidthMeters: Double?
    public var penaltySpotDistanceMeters: Double?

    public init(
        lengthMeters: Double,
        widthMeters: Double,
        centerCircleRadiusMeters: Double? = nil,
        penaltyAreaDepthMeters: Double? = nil,
        penaltyAreaWidthMeters: Double? = nil,
        goalAreaDepthMeters: Double? = nil,
        goalAreaWidthMeters: Double? = nil,
        penaltySpotDistanceMeters: Double? = nil
    ) {
        self.lengthMeters = lengthMeters
        self.widthMeters = widthMeters
        self.centerCircleRadiusMeters = centerCircleRadiusMeters
        self.penaltyAreaDepthMeters = penaltyAreaDepthMeters
        self.penaltyAreaWidthMeters = penaltyAreaWidthMeters
        self.goalAreaDepthMeters = goalAreaDepthMeters
        self.goalAreaWidthMeters = goalAreaWidthMeters
        self.penaltySpotDistanceMeters = penaltySpotDistanceMeters
    }
}

public struct FieldTemplate: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var pitchSize: PitchSize
    public var dimensions: PitchDimensions
    public var supportedMarkings: Set<LineMarking>
    public var defaultMarkings: Set<LineMarking>

    public init(
        id: UUID = UUID(),
        name: String,
        pitchSize: PitchSize,
        dimensions: PitchDimensions,
        supportedMarkings: Set<LineMarking>,
        defaultMarkings: Set<LineMarking>
    ) {
        self.id = id
        self.name = name
        self.pitchSize = pitchSize
        self.dimensions = dimensions
        self.supportedMarkings = supportedMarkings
        self.defaultMarkings = defaultMarkings
    }
}

public struct FieldTransform: Codable, Equatable, Sendable {
    public var translation: Vector2D
    public var rotationRadians: Double

    public init(translation: Vector2D = Vector2D(dx: 0, dy: 0), rotationRadians: Double = 0) {
        self.translation = translation
        self.rotationRadians = rotationRadians
    }

    public func apply(to point: Point2D) -> Point2D {
        point
            .rotated(by: rotationRadians)
            .translated(by: translation)
    }
}

public struct FieldLayout: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var templateID: UUID
    public var dimensions: PitchDimensions
    public var enabledMarkings: Set<LineMarking>
    public var transform: FieldTransform
    public var lockMode: PlacementLockMode

    public init(
        id: UUID = UUID(),
        name: String,
        templateID: UUID,
        dimensions: PitchDimensions,
        enabledMarkings: Set<LineMarking>,
        transform: FieldTransform = FieldTransform(),
        lockMode: PlacementLockMode = .center
    ) {
        self.id = id
        self.name = name
        self.templateID = templateID
        self.dimensions = dimensions
        self.enabledMarkings = enabledMarkings
        self.transform = transform
        self.lockMode = lockMode
    }
}

public struct VenueScan: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var venueName: String
    public var landmarkNotes: [String]
    public var landmarks: [VenueLandmark]
    public var recommendedRelocalizationHints: [String]
    public var preferredStartEdge: String?
    public var preferredRecoveryEdge: String?
    public var scanCoverageScore: Double
    public var worldMapData: Data?

    public init(
        id: UUID = UUID(),
        venueName: String,
        landmarkNotes: [String],
        landmarks: [VenueLandmark] = [],
        recommendedRelocalizationHints: [String],
        preferredStartEdge: String? = nil,
        preferredRecoveryEdge: String? = nil,
        scanCoverageScore: Double,
        worldMapData: Data? = nil
    ) {
        self.id = id
        self.venueName = venueName
        self.landmarkNotes = landmarkNotes
        self.landmarks = landmarks
        self.recommendedRelocalizationHints = recommendedRelocalizationHints
        self.preferredStartEdge = preferredStartEdge
        self.preferredRecoveryEdge = preferredRecoveryEdge
        self.scanCoverageScore = scanCoverageScore
        self.worldMapData = worldMapData
    }
}

public struct ProjectPackage: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var version: Int
    public var projectName: String
    public var venueScan: VenueScan
    public var templates: [FieldTemplate]
    public var layouts: [FieldLayout]
    public var createdAt: Date
    public var lockedAt: Date?

    public init(
        id: UUID = UUID(),
        version: Int = 1,
        projectName: String,
        venueScan: VenueScan,
        templates: [FieldTemplate],
        layouts: [FieldLayout],
        createdAt: Date = Date(),
        lockedAt: Date? = nil
    ) {
        self.id = id
        self.version = version
        self.projectName = projectName
        self.venueScan = venueScan
        self.templates = templates
        self.layouts = layouts
        self.createdAt = createdAt
        self.lockedAt = lockedAt
    }
}
