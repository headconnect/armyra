import Foundation
import ArmyraCore

protocol VenueScanService {
    func startSession(for venueScan: VenueScan) -> VenueScanSessionState
    func captureLandmark(_ landmark: String, session: VenueScanSessionState) -> VenueScanSessionState
    func advanceCoverage(session: VenueScanSessionState) -> VenueScanSessionState
    func updateLandmarkRole(
        landmark: String,
        role: LandmarkRole,
        session: VenueScanSessionState
    ) -> VenueScanSessionState
    func updatePreferredEdges(
        startEdge: String?,
        recoveryEdge: String?,
        session: VenueScanSessionState
    ) -> VenueScanSessionState
    func finalize(session: VenueScanSessionState, original: VenueScan) -> VenueScan
}

struct MockVenueScanService: VenueScanService {
    func startSession(for venueScan: VenueScan) -> VenueScanSessionState {
        makeSession(
            venueName: venueScan.venueName,
            capturedLandmarks: venueScan.landmarkNotes,
            landmarks: venueScan.landmarks,
            coveredSides: max(1, min(Int(round(venueScan.scanCoverageScore * 4)), 4)),
            preferredStartEdgeOverride: venueScan.preferredStartEdge,
            preferredRecoveryEdgeOverride: venueScan.preferredRecoveryEdge,
            fallbackHint: venueScan.recommendedRelocalizationHints.first ?? "Walk the touchline and capture stable landmarks."
        )
    }

    func captureLandmark(_ landmark: String, session: VenueScanSessionState) -> VenueScanSessionState {
        var capturedLandmarks = session.capturedLandmarks
        if !capturedLandmarks.contains(landmark) {
            capturedLandmarks.append(landmark)
        }
        var landmarks = session.landmarks
        if !landmarks.contains(where: { $0.label == landmark }) {
            landmarks.append(VenueLandmark(label: landmark))
        }

        return makeSession(
            venueName: session.venueName,
            capturedLandmarks: capturedLandmarks,
            landmarks: landmarks,
            coveredSides: min(max(session.coveredSides, 1), 4),
            preferredStartEdgeOverride: session.preferredStartEdge,
            preferredRecoveryEdgeOverride: session.preferredRecoveryEdge,
            fallbackHint: session.recommendedHint
        )
    }

    func advanceCoverage(session: VenueScanSessionState) -> VenueScanSessionState {
        return makeSession(
            venueName: session.venueName,
            capturedLandmarks: session.capturedLandmarks,
            landmarks: session.landmarks,
            coveredSides: min(session.coveredSides + 1, 4),
            preferredStartEdgeOverride: session.preferredStartEdge,
            preferredRecoveryEdgeOverride: session.preferredRecoveryEdge,
            fallbackHint: session.recommendedHint
        )
    }

    func updateLandmarkRole(
        landmark: String,
        role: LandmarkRole,
        session: VenueScanSessionState
    ) -> VenueScanSessionState {
        let updatedLandmarks = session.landmarks.map { savedLandmark in
            guard savedLandmark.label == landmark else { return savedLandmark }
            return VenueLandmark(id: savedLandmark.id, label: savedLandmark.label, role: role)
        }

        return makeSession(
            venueName: session.venueName,
            capturedLandmarks: session.capturedLandmarks,
            landmarks: updatedLandmarks,
            coveredSides: session.coveredSides,
            preferredStartEdgeOverride: role == .startCandidate ? landmark : session.preferredStartEdge,
            preferredRecoveryEdgeOverride: role == .recoveryCandidate ? landmark : session.preferredRecoveryEdge,
            fallbackHint: session.recommendedHint
        )
    }

    func updatePreferredEdges(
        startEdge: String?,
        recoveryEdge: String?,
        session: VenueScanSessionState
    ) -> VenueScanSessionState {
        makeSession(
            venueName: session.venueName,
            capturedLandmarks: session.capturedLandmarks,
            landmarks: session.landmarks,
            coveredSides: session.coveredSides,
            preferredStartEdgeOverride: startEdge,
            preferredRecoveryEdgeOverride: recoveryEdge,
            fallbackHint: session.recommendedHint
        )
    }

    func finalize(session: VenueScanSessionState, original: VenueScan) -> VenueScan {
        VenueScan(
            id: original.id,
            venueName: original.venueName,
            landmarkNotes: session.capturedLandmarks,
            landmarks: session.landmarks,
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
        landmarks: [VenueLandmark],
        coveredSides: Int,
        preferredStartEdgeOverride: String? = nil,
        preferredRecoveryEdgeOverride: String? = nil,
        fallbackHint: String
    ) -> VenueScanSessionState {
        let landmarkScore = min(Double(capturedLandmarks.count) / 6, 1)
        let sideScore = Double(coveredSides) / 4
        let readinessScore = min((landmarkScore * 0.55) + (sideScore * 0.45), 1)
        let phase: VenueScanPhase = readinessScore >= 0.8 && coveredSides >= 3 && capturedLandmarks.count >= 4 ? .ready : .scanning
        let preferredStartEdge = preferredStartEdgeOverride ?? landmarks.first(where: { $0.role == .startCandidate })?.label ?? capturedLandmarks.first
        let defaultRecoveryEdge = landmarks.first(where: { $0.role == .recoveryCandidate })?.label
            ?? (coveredSides >= 2 ? capturedLandmarks.dropFirst().first ?? capturedLandmarks.first : nil)
        let preferredRecoveryEdge = preferredRecoveryEdgeOverride ?? defaultRecoveryEdge

        return VenueScanSessionState(
            venueName: venueName,
            capturedLandmarks: capturedLandmarks,
            landmarks: landmarks,
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
                landmarks: landmarks,
                fallbackHint: fallbackHint
            )
        )
    }

    private func recommendation(
        preferredStartEdge: String?,
        preferredRecoveryEdge: String?,
        coveredSides: Int,
        readinessScore: Double,
        landmarks: [VenueLandmark],
        fallbackHint: String
    ) -> String {
        let hasStartCandidate = landmarks.contains(where: { $0.role == .startCandidate })
        let hasRecoveryCandidate = landmarks.contains(where: { $0.role == .recoveryCandidate })

        if coveredSides <= 1 {
            return "Capture a second landmark-bearing edge before locking the scan. One-sided coverage is not robust enough."
        }

        if !hasStartCandidate {
            return "Tag one captured object as the start-side candidate so the parent knows exactly where to begin relocalization."
        }

        if let preferredStartEdge,
           !landmarks.contains(where: {
               $0.label.caseInsensitiveCompare(preferredStartEdge) == .orderedSame && $0.role == .startCandidate
           }) {
            return "The chosen start edge is not tagged as a start-side candidate yet. Re-tag it before locking the scan."
        }

        if !hasRecoveryCandidate {
            return "Tag a separate captured object as the recovery-side candidate so the parent has a clear fallback edge."
        }

        if let preferredRecoveryEdge,
           !landmarks.contains(where: {
               $0.label.caseInsensitiveCompare(preferredRecoveryEdge) == .orderedSame && $0.role == .recoveryCandidate
           }) {
            return "The chosen recovery edge is not tagged as a recovery-side candidate yet. Re-tag it before locking the scan."
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
