import Foundation

public enum PlanningReadinessLevel: String, Codable, CaseIterable, Sendable {
    case ready
    case caution
    case needsWork
}

public struct PlanningReadinessIssue: Equatable, Identifiable, Sendable {
    public var id: UUID
    public var message: String
    public var level: PlanningReadinessLevel

    public init(id: UUID = UUID(), message: String, level: PlanningReadinessLevel) {
        self.id = id
        self.message = message
        self.level = level
    }
}

public struct PlanningReadinessSummary: Equatable, Sendable {
    public var level: PlanningReadinessLevel
    public var score: Double
    public var parentSafe: Bool
    public var summary: String
    public var handoffGuidance: [String]
    public var issues: [PlanningReadinessIssue]

    public init(
        level: PlanningReadinessLevel,
        score: Double,
        parentSafe: Bool,
        summary: String,
        handoffGuidance: [String],
        issues: [PlanningReadinessIssue]
    ) {
        self.level = level
        self.score = score
        self.parentSafe = parentSafe
        self.summary = summary
        self.handoffGuidance = handoffGuidance
        self.issues = issues
    }
}

public enum PlanningReadinessAnalyzer {
    public static func summarize(project: ProjectPackage) -> PlanningReadinessSummary {
        let overlaps = FieldLayoutAnalysis.overlaps(in: project.layouts)
        let closePairs = FieldLayoutAnalysis.tightSpacing(in: project.layouts, minimumGap: 4)
        let laneIssues = FieldLayoutAnalysis.practicalLaneIssues(in: project.layouts, minimumLaneWidth: 6)
        let corridorSummary = FieldLayoutAnalysis.setupCorridorSummary(in: project.layouts)
        let venueScanReadiness = VenueScanReadinessAnalyzer.summarize(venueScan: project.venueScan)
        var issues: [PlanningReadinessIssue] = []
        var handoffGuidance: [String] = []
        var score = venueScanReadiness.score

        issues.append(contentsOf: venueScanReadiness.issues.map {
            PlanningReadinessIssue(
                message: $0.message,
                level: mapVenueScanLevel($0.level)
            )
        })

        if overlaps.isEmpty == false {
            issues.append(
                PlanningReadinessIssue(
                    message: "One or more pitches overlap in the current plan.",
                    level: .needsWork
                )
            )
            score -= 0.4
        }

        if closePairs.isEmpty == false {
            issues.append(
                PlanningReadinessIssue(
                    message: "Some pitches are very close together and may be awkward to chalk accurately.",
                    level: .caution
                )
            )
            score -= 0.15
        }

        if laneIssues.contains(where: { $0.laneWidthMeters < 3 }) {
            issues.append(
                PlanningReadinessIssue(
                    message: "Some adjacent pitches leave almost no practical chalking lane for a trolley or setup team.",
                    level: .needsWork
                )
            )
            score -= 0.25
        } else if laneIssues.isEmpty == false {
            issues.append(
                PlanningReadinessIssue(
                    message: "Some adjacent pitches leave only a narrow chalking lane, which may slow setup and recovery.",
                    level: .caution
                )
            )
            score -= 0.12
        }

        if let corridorSummary {
            let bestCorridorWidth = max(
                corridorSummary.widestHorizontalBandMeters,
                corridorSummary.widestVerticalBandMeters
            )
            let expectedBoundaryOrientation: VenueEdgeOrientation =
                corridorSummary.preferredAxis == .vertical ? .horizontalBoundary : .verticalBoundary
            let corridorGuidance = corridorSummary.preferredAxis == .vertical
                ? "Preferred venue approach is north-south, so the handoff should favor goal-line style re-entry zones."
                : "Preferred venue approach is east-west, so the handoff should favor touchline style re-entry zones."
            handoffGuidance.append(corridorGuidance)

            if bestCorridorWidth < 4 {
                issues.append(
                    PlanningReadinessIssue(
                        message: "The overall layout leaves no meaningful setup corridor across the venue for trolleys or volunteers.",
                        level: .needsWork
                    )
                )
                score -= 0.2
            } else if min(
                corridorSummary.widestHorizontalBandMeters,
                corridorSummary.widestVerticalBandMeters
            ) < 3 {
                issues.append(
                    PlanningReadinessIssue(
                        message: "The venue only has a usable setup corridor in one direction, which may complicate setup on busy days.",
                        level: .caution
                    )
                )
                score -= 0.08
            }

            let chosenEntryEdges: [(kind: String, label: String, orientation: VenueEdgeOrientation)] = [
                project.venueScan.preferredStartEdge.map { ("Primary re-entry zone", $0, FieldLayoutAnalysis.inferEdgeOrientation(from: $0)) },
                project.venueScan.preferredRecoveryEdge.map { ("Backup recovery zone", $0, FieldLayoutAnalysis.inferEdgeOrientation(from: $0)) }
            ]
            .compactMap { entry in
                guard let entry, let orientation = entry.2 else { return nil }
                return (entry.0, entry.1, orientation)
            }

            if let startEdge = project.venueScan.preferredStartEdge {
                handoffGuidance.append("Primary re-entry zone: \(startEdge).")
            }

            if let recoveryEdge = project.venueScan.preferredRecoveryEdge {
                handoffGuidance.append("Backup recovery zone: \(recoveryEdge).")
            }

            if chosenEntryEdges.isEmpty == false && chosenEntryEdges.allSatisfy({ $0.orientation != expectedBoundaryOrientation }) {
                issues.append(
                    PlanningReadinessIssue(
                        message: "The chosen start and recovery edges do not seem to line up with the strongest venue setup corridor.",
                        level: .caution
                    )
                )
                score -= 0.08
            } else if chosenEntryEdges.contains(where: { $0.orientation != expectedBoundaryOrientation }) {
                issues.append(
                    PlanningReadinessIssue(
                        message: "One of the chosen re-entry zones does not line up with the strongest venue setup corridor.",
                        level: .caution
                    )
                )
                score -= 0.05
            }
        }

        if project.layouts.isEmpty {
            issues.append(
                PlanningReadinessIssue(
                    message: "No pitches have been placed yet.",
                    level: .needsWork
                )
            )
            score = 0
        }

        score = min(max(score, 0), 1)

        let level: PlanningReadinessLevel
        if issues.contains(where: { $0.level == .needsWork }) {
            level = .needsWork
        } else if issues.isEmpty == false {
            level = .caution
        } else {
            level = .ready
        }

        let summary: String
        switch level {
        case .ready:
            summary = "Ready for chalking handoff."
        case .caution:
            summary = "Usable for chalking, but the parent may need extra context or recovery time."
        case .needsWork:
            summary = "Not parent-safe yet. Improve scanning or layout spacing before handoff."
        }

        return PlanningReadinessSummary(
            level: level,
            score: score,
            parentSafe: level == .ready || (level == .caution && venueScanReadiness.canLockForHandoff),
            summary: summary,
            handoffGuidance: handoffGuidance,
            issues: issues
        )
    }

    private static func mapVenueScanLevel(_ level: VenueScanReadinessLevel) -> PlanningReadinessLevel {
        switch level {
        case .ready:
            return .ready
        case .caution:
            return .caution
        case .needsWork:
            return .needsWork
        }
    }
}
