import Foundation

public enum VenueReadinessLevel: String, Codable, Equatable, Sendable {
    case low
    case moderate
    case high
}

public struct ChalkingPreflight: Equatable, Sendable {
    public var readinessLevel: VenueReadinessLevel
    public var startHint: String
    public var recoveryHint: String
    public var checklist: [String]
    public var warning: String?

    public init(
        readinessLevel: VenueReadinessLevel,
        startHint: String,
        recoveryHint: String,
        checklist: [String],
        warning: String?
    ) {
        self.readinessLevel = readinessLevel
        self.startHint = startHint
        self.recoveryHint = recoveryHint
        self.checklist = checklist
        self.warning = warning
    }
}

public enum ChalkingGuidancePlanner {
    public static func makePreflight(
        project: ProjectPackage,
        layout: FieldLayout
    ) -> ChalkingPreflight {
        let readinessLevel = readinessLevel(for: project.venueScan)
        let startHint = project.venueScan.preferredStartEdge.map {
            "Start from \(edgePhrase($0)) before chalking."
        } ?? project.venueScan.recommendedRelocalizationHints.first
            ?? "Start from the strongest landmark edge before chalking."
        let recoveryHint = project.venueScan.preferredRecoveryEdge.map {
            "If tracking drifts, return toward \(edgePhrase($0)) and relocalize."
        } ?? project.venueScan.recommendedRelocalizationHints.dropFirst().first
            ?? "If tracking drifts, turn back toward a known landmark edge and relocalize."

        let checklist = [
            "Mount the phone securely to the chalking trolley.",
            "Set up on \(project.venueScan.preferredStartEdge.map(edgePhrase) ?? "the strongest landmark edge").",
            "Begin from \(startReference(for: layout.lockMode)).",
            "Chalk the outer perimeter before interior markings.",
            "If tracking softens, head back toward \(project.venueScan.preferredRecoveryEdge.map(edgePhrase) ?? "the recovery edge") and look back toward known landmarks."
        ]

        return ChalkingPreflight(
            readinessLevel: readinessLevel,
            startHint: startHint,
            recoveryHint: recoveryHint,
            checklist: checklist,
            warning: warning(for: project.venueScan, readinessLevel: readinessLevel)
        )
    }

    private static func readinessLevel(for venueScan: VenueScan) -> VenueReadinessLevel {
        switch venueScan.scanCoverageScore {
        case 0.75...:
            return .high
        case 0.45...:
            return .moderate
        default:
            return .low
        }
    }

    private static func warning(
        for venueScan: VenueScan,
        readinessLevel: VenueReadinessLevel
    ) -> String? {
        if readinessLevel == .low {
            return "Venue scan coverage is still light. Expect more recovery stops while chalking."
        }

        if venueScan.landmarkNotes.count < 2 {
            return "Only a small number of landmarks are saved. Add more durable landmarks during planning if possible."
        }

        return nil
    }

    private static func startReference(for lockMode: PlacementLockMode) -> String {
        switch lockMode {
        case .center:
            return "the center reference used during planning"
        case .corner(let corner):
            switch corner {
            case .topLeft:
                return "the top-left corner reference"
            case .topRight:
                return "the top-right corner reference"
            case .bottomLeft:
                return "the bottom-left corner reference"
            case .bottomRight:
                return "the bottom-right corner reference"
            }
        }
    }

    private static func edgePhrase(_ label: String) -> String {
        let normalized = label.lowercased()
        if normalized.contains(" side") || normalized.contains(" touchline") || normalized.contains(" edge") {
            return "the \(normalized)"
        }

        return "the \(normalized) side"
    }
}
