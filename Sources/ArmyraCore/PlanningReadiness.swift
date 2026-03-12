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
    public var issues: [PlanningReadinessIssue]

    public init(
        level: PlanningReadinessLevel,
        score: Double,
        parentSafe: Bool,
        summary: String,
        issues: [PlanningReadinessIssue]
    ) {
        self.level = level
        self.score = score
        self.parentSafe = parentSafe
        self.summary = summary
        self.issues = issues
    }
}

public enum PlanningReadinessAnalyzer {
    public static func summarize(project: ProjectPackage) -> PlanningReadinessSummary {
        let overlaps = FieldLayoutAnalysis.overlaps(in: project.layouts)
        let closePairs = FieldLayoutAnalysis.tightSpacing(in: project.layouts, minimumGap: 4)
        var issues: [PlanningReadinessIssue] = []
        var score = min(max(project.venueScan.scanCoverageScore, 0), 1)

        if project.venueScan.scanCoverageScore < 0.45 {
            issues.append(
                PlanningReadinessIssue(
                    message: "Landmark coverage is weak. A first-time parent may struggle to relocalize.",
                    level: .needsWork
                )
            )
            score -= 0.35
        } else if project.venueScan.scanCoverageScore < 0.7 {
            issues.append(
                PlanningReadinessIssue(
                    message: "Landmark coverage is usable but recovery may require extra coaching.",
                    level: .caution
                )
            )
            score -= 0.15
        }

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
            parentSafe: level == .ready || (level == .caution && project.venueScan.scanCoverageScore >= 0.6),
            summary: summary,
            issues: issues
        )
    }
}
