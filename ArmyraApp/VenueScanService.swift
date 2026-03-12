import Foundation
import ArmyraCore

protocol VenueScanService {
    func startSession(for venueScan: VenueScan) -> VenueScanSessionState
    func captureLandmark(_ landmark: String, session: VenueScanSessionState) -> VenueScanSessionState
    func advanceCoverage(session: VenueScanSessionState) -> VenueScanSessionState
    func finalize(session: VenueScanSessionState, original: VenueScan) -> VenueScan
}

struct MockVenueScanService: VenueScanService {
    func startSession(for venueScan: VenueScan) -> VenueScanSessionState {
        makeSession(
            venueName: venueScan.venueName,
            capturedLandmarks: venueScan.landmarkNotes,
            coveredSides: max(1, min(Int(round(venueScan.scanCoverageScore * 4)), 4)),
            fallbackHint: venueScan.recommendedRelocalizationHints.first ?? "Walk the touchline and capture stable landmarks."
        )
    }

    func captureLandmark(_ landmark: String, session: VenueScanSessionState) -> VenueScanSessionState {
        var capturedLandmarks = session.capturedLandmarks
        if !capturedLandmarks.contains(landmark) {
            capturedLandmarks.append(landmark)
        }

        return makeSession(
            venueName: session.venueName,
            capturedLandmarks: capturedLandmarks,
            coveredSides: min(max(session.coveredSides, 1), 4),
            fallbackHint: session.recommendedHint
        )
    }

    func advanceCoverage(session: VenueScanSessionState) -> VenueScanSessionState {
        return makeSession(
            venueName: session.venueName,
            capturedLandmarks: session.capturedLandmarks,
            coveredSides: min(session.coveredSides + 1, 4),
            fallbackHint: session.recommendedHint
        )
    }

    func finalize(session: VenueScanSessionState, original: VenueScan) -> VenueScan {
        VenueScan(
            id: original.id,
            venueName: original.venueName,
            landmarkNotes: session.capturedLandmarks,
            recommendedRelocalizationHints: buildRelocalizationHints(for: session),
            preferredStartEdge: session.preferredStartEdge,
            preferredRecoveryEdge: session.preferredRecoveryEdge,
            scanCoverageScore: session.readinessScore,
            worldMapData: original.worldMapData
        )
    }

    private func makeSession(
        venueName: String,
        capturedLandmarks: [String],
        coveredSides: Int,
        fallbackHint: String
    ) -> VenueScanSessionState {
        let landmarkScore = min(Double(capturedLandmarks.count) / 6, 1)
        let sideScore = Double(coveredSides) / 4
        let readinessScore = min((landmarkScore * 0.55) + (sideScore * 0.45), 1)
        let phase: VenueScanPhase = readinessScore >= 0.8 && coveredSides >= 3 && capturedLandmarks.count >= 4 ? .ready : .scanning
        let preferredStartEdge = capturedLandmarks.first
        let preferredRecoveryEdge = coveredSides >= 2 ? capturedLandmarks.dropFirst().first ?? capturedLandmarks.first : nil

        return VenueScanSessionState(
            venueName: venueName,
            capturedLandmarks: capturedLandmarks,
            coveredSides: coveredSides,
            preferredStartEdge: preferredStartEdge,
            preferredRecoveryEdge: preferredRecoveryEdge,
            readinessScore: readinessScore,
            phase: phase,
            recommendedHint: recommendation(
                preferredStartEdge: preferredStartEdge,
                preferredRecoveryEdge: preferredRecoveryEdge,
                coveredSides: coveredSides,
                readinessScore: readinessScore,
                fallbackHint: fallbackHint
            )
        )
    }

    private func recommendation(
        preferredStartEdge: String?,
        preferredRecoveryEdge: String?,
        coveredSides: Int,
        readinessScore: Double,
        fallbackHint: String
    ) -> String {
        if coveredSides <= 1 {
            return "Capture a second landmark-bearing edge before locking the scan. One-sided coverage is not robust enough."
        }

        if preferredStartEdge == nil {
            return "Add more durable landmarks like fences, buildings, or floodlight masts before locking the scan."
        }

        if preferredRecoveryEdge == nil || readinessScore < 0.8 || coveredSides < 3 {
            return "Keep improving coverage until the parent has a named start edge and a separate recovery edge."
        }

        if let preferredStartEdge, let preferredRecoveryEdge {
            return "Coverage is strong. Use \(edgePhrase(preferredStartEdge)) as the start edge and \(edgePhrase(preferredRecoveryEdge)) as the backup recovery edge."
        }

        return fallbackHint
    }

    private func buildRelocalizationHints(for session: VenueScanSessionState) -> [String] {
        let primaryLandmark = session.preferredStartEdge.map(edgePhrase)
        let recoveryLandmark = session.preferredRecoveryEdge.map(edgePhrase)

        let startHint = primaryLandmark.map {
            "Start chalking from \($0) for the strongest initial relocalization."
        } ?? session.recommendedHint

        let recoveryHint = recoveryLandmark.map {
            "If tracking softens, pause and turn back toward \($0) before resuming."
        } ?? "If tracking softens, return to the strongest landmark edge before resuming."

        return [startHint, recoveryHint, session.recommendedHint]
    }

    private func edgePhrase(_ label: String) -> String {
        let normalized = label.lowercased()
        if normalized.contains(" side") || normalized.contains(" touchline") || normalized.contains(" edge") {
            return "the \(normalized)"
        }

        return "the \(normalized) side"
    }
}
