import Foundation

public enum VenueScanReadinessLevel: String, Codable, CaseIterable, Sendable {
    case ready
    case caution
    case needsWork
}

public struct VenueScanReadinessIssue: Equatable, Identifiable, Sendable {
    public var id: UUID
    public var message: String
    public var level: VenueScanReadinessLevel

    public init(id: UUID = UUID(), message: String, level: VenueScanReadinessLevel) {
        self.id = id
        self.message = message
        self.level = level
    }
}

public struct VenueScanReadinessSummary: Equatable, Sendable {
    public var level: VenueScanReadinessLevel
    public var score: Double
    public var canLockForHandoff: Bool
    public var summary: String
    public var issues: [VenueScanReadinessIssue]

    public init(
        level: VenueScanReadinessLevel,
        score: Double,
        canLockForHandoff: Bool,
        summary: String,
        issues: [VenueScanReadinessIssue]
    ) {
        self.level = level
        self.score = score
        self.canLockForHandoff = canLockForHandoff
        self.summary = summary
        self.issues = issues
    }
}

public enum VenueScanReadinessAnalyzer {
    public static func summarize(session: VenueScanSessionState) -> VenueScanReadinessSummary {
        let derivedHintCount = session.coveredSides >= 3 && session.capturedLandmarks.count >= 4 ? 2 : 1
        return summarize(
            landmarkCount: session.capturedLandmarks.count,
            coveredSides: session.coveredSides,
            readinessScore: session.readinessScore,
            relocalizationHintCount: derivedHintCount
        )
    }

    public static func summarize(venueScan: VenueScan) -> VenueScanReadinessSummary {
        let estimatedSides = max(1, min(Int(round(venueScan.scanCoverageScore * 4)), 4))
        return summarize(
            landmarkCount: venueScan.landmarkNotes.count,
            coveredSides: estimatedSides,
            readinessScore: venueScan.scanCoverageScore,
            relocalizationHintCount: venueScan.recommendedRelocalizationHints.count
        )
    }

    private static func summarize(
        landmarkCount: Int,
        coveredSides: Int,
        readinessScore: Double,
        relocalizationHintCount: Int
    ) -> VenueScanReadinessSummary {
        var issues: [VenueScanReadinessIssue] = []
        var score = min(max(readinessScore, 0), 1)

        if coveredSides <= 1 {
            issues.append(
                VenueScanReadinessIssue(
                    message: "Only one edge has usable landmark coverage. Parents may not be able to recover once the trolley turns away.",
                    level: .needsWork
                )
            )
            score -= 0.35
        } else if coveredSides == 2 {
            issues.append(
                VenueScanReadinessIssue(
                    message: "Coverage is concentrated on two sides. Chalking should still have a deliberate recovery edge.",
                    level: .caution
                )
            )
            score -= 0.12
        }

        if landmarkCount < 3 {
            issues.append(
                VenueScanReadinessIssue(
                    message: "Too few durable landmarks have been captured. Add fences, light posts, buildings, or other fixed objects.",
                    level: .needsWork
                )
            )
            score -= 0.3
        } else if landmarkCount < 5 {
            issues.append(
                VenueScanReadinessIssue(
                    message: "Landmark capture is usable but still thin. One or two more durable references would make handoff safer.",
                    level: .caution
                )
            )
            score -= 0.1
        }

        if readinessScore < 0.55 {
            issues.append(
                VenueScanReadinessIssue(
                    message: "The scan has not yet reached a stable relocalization baseline for first-time parent use.",
                    level: .needsWork
                )
            )
            score -= 0.3
        } else if readinessScore < 0.75 {
            issues.append(
                VenueScanReadinessIssue(
                    message: "The scan is usable, but relocalization may still require careful setup on the strongest edge.",
                    level: .caution
                )
            )
            score -= 0.1
        }

        if relocalizationHintCount < 2 {
            issues.append(
                VenueScanReadinessIssue(
                    message: "Add at least one explicit recovery hint so the parent knows where to return if tracking softens.",
                    level: .caution
                )
            )
            score -= 0.08
        }

        score = min(max(score, 0), 1)

        let level: VenueScanReadinessLevel
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
            summary = "Venue scan is strong enough to lock for parent handoff."
        case .caution:
            summary = "Venue scan is usable, but the club should review recovery instructions before locking it."
        case .needsWork:
            summary = "Venue scan is not robust enough to hand off yet."
        }

        return VenueScanReadinessSummary(
            level: level,
            score: score,
            canLockForHandoff: level == .ready,
            summary: summary,
            issues: issues
        )
    }
}
