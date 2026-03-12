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

        return VenueScanSessionState(
            venueName: venueName,
            capturedLandmarks: capturedLandmarks,
            coveredSides: coveredSides,
            readinessScore: readinessScore,
            phase: phase,
            recommendedHint: recommendation(
                capturedLandmarks: capturedLandmarks,
                coveredSides: coveredSides,
                readinessScore: readinessScore,
                fallbackHint: fallbackHint
            )
        )
    }

    private func recommendation(
        capturedLandmarks: [String],
        coveredSides: Int,
        readinessScore: Double,
        fallbackHint: String
    ) -> String {
        if coveredSides <= 1 {
            return "Capture a second landmark-bearing edge before locking the scan. One-sided coverage is not robust enough."
        }

        if capturedLandmarks.count < 3 {
            return "Add more durable landmarks like fences, buildings, or floodlight masts before locking the scan."
        }

        if readinessScore < 0.8 || coveredSides < 3 {
            return "Keep improving coverage until the parent has a clear start edge and a separate recovery edge."
        }

        return capturedLandmarks.first.map {
            "Coverage is strong. Use \($0.lowercased()) as the preferred start edge and keep another landmark side in reserve for recovery."
        } ?? fallbackHint
    }

    private func buildRelocalizationHints(for session: VenueScanSessionState) -> [String] {
        let primaryLandmark = session.capturedLandmarks.first?.lowercased()
        let recoveryLandmark = session.capturedLandmarks.dropFirst().first?.lowercased()

        let startHint = primaryLandmark.map {
            "Start chalking from the \($0) side for the strongest initial relocalization."
        } ?? session.recommendedHint

        let recoveryHint = recoveryLandmark.map {
            "If tracking softens, pause and turn back toward the \($0) side before resuming."
        } ?? "If tracking softens, return to the strongest landmark edge before resuming."

        return [startHint, recoveryHint, session.recommendedHint]
    }
}
