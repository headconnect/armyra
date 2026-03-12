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
    public var startCandidateCount: Int
    public var recoveryCandidateCount: Int
    public var generalLandmarkCount: Int
    public var issues: [VenueScanReadinessIssue]

    public init(
        level: VenueScanReadinessLevel,
        score: Double,
        canLockForHandoff: Bool,
        summary: String,
        startCandidateCount: Int,
        recoveryCandidateCount: Int,
        generalLandmarkCount: Int,
        issues: [VenueScanReadinessIssue]
    ) {
        self.level = level
        self.score = score
        self.canLockForHandoff = canLockForHandoff
        self.summary = summary
        self.startCandidateCount = startCandidateCount
        self.recoveryCandidateCount = recoveryCandidateCount
        self.generalLandmarkCount = generalLandmarkCount
        self.issues = issues
    }
}

public enum VenueScanReadinessAnalyzer {
    public static func summarize(session: VenueScanSessionState) -> VenueScanReadinessSummary {
        let derivedHintCount = session.coveredSides >= 3 && session.capturedLandmarks.count >= 4 ? 2 : 1
        let roleCounts = roleCounts(for: session.landmarks)
        return summarize(
            landmarkCount: session.capturedLandmarks.count,
            coveredSides: session.coveredSides,
            startEdgeLabel: session.preferredStartEdge,
            recoveryEdgeLabel: session.preferredRecoveryEdge,
            hasPreferredStartEdge: session.preferredStartEdge?.isEmpty == false,
            hasPreferredRecoveryEdge: session.preferredRecoveryEdge?.isEmpty == false,
            preferredStartEdgeMatchesRole: roleMatches(label: session.preferredStartEdge, role: .startCandidate, landmarks: session.landmarks),
            preferredRecoveryEdgeMatchesRole: roleMatches(label: session.preferredRecoveryEdge, role: .recoveryCandidate, landmarks: session.landmarks),
            readinessScore: session.readinessScore,
            relocalizationHintCount: derivedHintCount,
            startCandidateCount: roleCounts.startCandidateCount,
            recoveryCandidateCount: roleCounts.recoveryCandidateCount,
            generalLandmarkCount: roleCounts.generalLandmarkCount
        )
    }

    public static func summarize(venueScan: VenueScan) -> VenueScanReadinessSummary {
        let estimatedSides = max(1, min(Int(round(venueScan.scanCoverageScore * 4)), 4))
        let roleCounts = roleCounts(for: venueScan.landmarks)
        return summarize(
            landmarkCount: venueScan.landmarkNotes.count,
            coveredSides: estimatedSides,
            startEdgeLabel: venueScan.preferredStartEdge,
            recoveryEdgeLabel: venueScan.preferredRecoveryEdge,
            hasPreferredStartEdge: venueScan.preferredStartEdge?.isEmpty == false,
            hasPreferredRecoveryEdge: venueScan.preferredRecoveryEdge?.isEmpty == false,
            preferredStartEdgeMatchesRole: roleMatches(label: venueScan.preferredStartEdge, role: .startCandidate, landmarks: venueScan.landmarks),
            preferredRecoveryEdgeMatchesRole: roleMatches(label: venueScan.preferredRecoveryEdge, role: .recoveryCandidate, landmarks: venueScan.landmarks),
            readinessScore: venueScan.scanCoverageScore,
            relocalizationHintCount: venueScan.recommendedRelocalizationHints.count,
            startCandidateCount: roleCounts.startCandidateCount,
            recoveryCandidateCount: roleCounts.recoveryCandidateCount,
            generalLandmarkCount: roleCounts.generalLandmarkCount
        )
    }

    private static func summarize(
        landmarkCount: Int,
        coveredSides: Int,
        startEdgeLabel: String?,
        recoveryEdgeLabel: String?,
        hasPreferredStartEdge: Bool,
        hasPreferredRecoveryEdge: Bool,
        preferredStartEdgeMatchesRole: Bool,
        preferredRecoveryEdgeMatchesRole: Bool,
        readinessScore: Double,
        relocalizationHintCount: Int,
        startCandidateCount: Int,
        recoveryCandidateCount: Int,
        generalLandmarkCount: Int
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

        if !hasPreferredStartEdge {
            issues.append(
                VenueScanReadinessIssue(
                    message: "No preferred start edge has been identified yet. The club should name the strongest edge for initial relocalization.",
                    level: .caution
                )
            )
            score -= 0.08
        }

        if startCandidateCount == 0 {
            issues.append(
                VenueScanReadinessIssue(
                    message: "No captured landmark has been tagged as a start-side candidate yet. Tag the clearest setup-side object before handoff.",
                    level: landmarkCount >= 4 ? .caution : .needsWork
                )
            )
            score -= landmarkCount >= 4 ? 0.08 : 0.14
        } else if hasPreferredStartEdge && !preferredStartEdgeMatchesRole {
            issues.append(
                VenueScanReadinessIssue(
                    message: "The chosen start edge is not backed by a landmark tagged as a start-side candidate. Re-tag the landmark or pick a different start edge.",
                    level: .caution
                )
            )
            score -= 0.08
        }

        if !hasPreferredRecoveryEdge {
            issues.append(
                VenueScanReadinessIssue(
                    message: "No backup recovery edge has been identified yet. Parents need a clear place to return when tracking softens.",
                    level: .caution
                )
            )
            score -= 0.08
        }

        if recoveryCandidateCount == 0 {
            issues.append(
                VenueScanReadinessIssue(
                    message: "No captured landmark has been tagged as a recovery-side candidate yet. The club should mark a clear fallback edge for parents.",
                    level: coveredSides >= 3 ? .caution : .needsWork
                )
            )
            score -= coveredSides >= 3 ? 0.08 : 0.14
        } else if hasPreferredRecoveryEdge && !preferredRecoveryEdgeMatchesRole {
            issues.append(
                VenueScanReadinessIssue(
                    message: "The chosen recovery edge is not backed by a landmark tagged as a recovery-side candidate. Re-tag the landmark or pick a different recovery edge.",
                    level: .caution
                )
            )
            score -= 0.08
        }

        if let startEdgeLabel, let recoveryEdgeLabel,
           startEdgeLabel.caseInsensitiveCompare(recoveryEdgeLabel) == .orderedSame {
            issues.append(
                VenueScanReadinessIssue(
                    message: "The start edge and recovery edge are the same. Pick a separate backup edge so recovery is more practical.",
                    level: .caution
                )
            )
            score -= 0.08
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

        if generalLandmarkCount == 0 && landmarkCount >= 3 {
            issues.append(
                VenueScanReadinessIssue(
                    message: "All captured landmarks are tagged as handoff edges. Keep at least one general reference so recovery is not tied to only two objects.",
                    level: .caution
                )
            )
            score -= 0.05
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
            startCandidateCount: startCandidateCount,
            recoveryCandidateCount: recoveryCandidateCount,
            generalLandmarkCount: generalLandmarkCount,
            issues: issues
        )
    }

    private static func roleCounts(for landmarks: [VenueLandmark]) -> (
        startCandidateCount: Int,
        recoveryCandidateCount: Int,
        generalLandmarkCount: Int
    ) {
        let startCandidateCount = landmarks.filter { $0.role == .startCandidate }.count
        let recoveryCandidateCount = landmarks.filter { $0.role == .recoveryCandidate }.count
        let generalLandmarkCount = landmarks.filter { $0.role == .general }.count
        return (startCandidateCount, recoveryCandidateCount, generalLandmarkCount)
    }

    private static func roleMatches(label: String?, role: LandmarkRole, landmarks: [VenueLandmark]) -> Bool {
        guard let label, !label.isEmpty else { return false }
        return landmarks.contains {
            $0.role == role && labelsLooselyMatch($0.label, label)
        }
    }

    private static func labelsLooselyMatch(_ lhs: String, _ rhs: String) -> Bool {
        let normalizedLHS = normalizeLabel(lhs)
        let normalizedRHS = normalizeLabel(rhs)
        return normalizedLHS == normalizedRHS
            || normalizedLHS.contains(normalizedRHS)
            || normalizedRHS.contains(normalizedLHS)
    }

    private static func normalizeLabel(_ label: String) -> String {
        label
            .lowercased()
            .replacingOccurrences(of: "side", with: "")
            .replacingOccurrences(of: "edge", with: "")
            .replacingOccurrences(of: "touchline", with: "")
            .replacingOccurrences(of: "goal line", with: "")
            .replacingOccurrences(of: "goal-line", with: "")
            .replacingOccurrences(of: "goal", with: "")
            .replacingOccurrences(of: "line", with: "")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
