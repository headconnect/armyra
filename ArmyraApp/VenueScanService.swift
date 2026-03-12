import ArmyraCore

protocol VenueScanService {
    func startSession(for venueScan: VenueScan) -> VenueScanSessionState
    func captureLandmark(_ landmark: String, session: VenueScanSessionState) -> VenueScanSessionState
    func advanceCoverage(session: VenueScanSessionState) -> VenueScanSessionState
    func finalize(session: VenueScanSessionState, original: VenueScan) -> VenueScan
}

struct MockVenueScanService: VenueScanService {
    func startSession(for venueScan: VenueScan) -> VenueScanSessionState {
        VenueScanSessionState(
            venueName: venueScan.venueName,
            capturedLandmarks: venueScan.landmarkNotes,
            coveredSides: max(1, min(Int(round(venueScan.scanCoverageScore * 4)), 4)),
            readinessScore: venueScan.scanCoverageScore,
            phase: venueScan.scanCoverageScore >= 0.7 ? .ready : .scanning,
            recommendedHint: venueScan.recommendedRelocalizationHints.first ?? "Walk the touchline and capture stable landmarks."
        )
    }

    func captureLandmark(_ landmark: String, session: VenueScanSessionState) -> VenueScanSessionState {
        var capturedLandmarks = session.capturedLandmarks
        if !capturedLandmarks.contains(landmark) {
            capturedLandmarks.append(landmark)
        }

        let readinessScore = min(Double(capturedLandmarks.count) / 6, 1)
        let phase: VenueScanPhase = readinessScore >= 0.7 ? .ready : .scanning

        return VenueScanSessionState(
            venueName: session.venueName,
            capturedLandmarks: capturedLandmarks,
            coveredSides: min(max(session.coveredSides, 1), 4),
            readinessScore: readinessScore,
            phase: phase,
            recommendedHint: phase == .ready
                ? "Enough landmarks captured. You can lock this venue or keep improving coverage."
                : "Capture durable objects on another edge before locking the scan."
        )
    }

    func advanceCoverage(session: VenueScanSessionState) -> VenueScanSessionState {
        let coveredSides = min(session.coveredSides + 1, 4)
        let readinessScore = max(session.readinessScore, Double(coveredSides) / 4)
        let phase: VenueScanPhase = readinessScore >= 0.7 ? .ready : .scanning

        return VenueScanSessionState(
            venueName: session.venueName,
            capturedLandmarks: session.capturedLandmarks,
            coveredSides: coveredSides,
            readinessScore: readinessScore,
            phase: phase,
            recommendedHint: coveredSides >= 3
                ? "Coverage is broad enough for intermittent landmark loss."
                : "Try to cover at least one more side so chalking can recover more reliably."
        )
    }

    func finalize(session: VenueScanSessionState, original: VenueScan) -> VenueScan {
        VenueScan(
            id: original.id,
            venueName: original.venueName,
            landmarkNotes: session.capturedLandmarks,
            recommendedRelocalizationHints: [session.recommendedHint],
            scanCoverageScore: session.readinessScore,
            worldMapData: original.worldMapData
        )
    }
}
