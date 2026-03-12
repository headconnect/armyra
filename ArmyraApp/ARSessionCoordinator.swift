import Foundation
import ArmyraCore

protocol ARSessionCoordinator {
    func startPlanningSession(for venueScan: VenueScan)
    func startChalkingSession(for venueScan: VenueScan, assetData: Data?)
    func capturePlanningAsset(for venueScan: VenueScan) async -> (VenueTrackingAssetRecord, Data?)
    func stopSession()
    func currentDiagnostics(
        for venueScan: VenueScan,
        asset: VenueTrackingAssetRecord?,
        payload: Data?
    ) -> ARSessionDiagnostics
    func planningSnapshot(for venueScan: VenueScan) -> VenueTrackingSnapshot
    func recordPlanningAsset(for venueScan: VenueScan) -> VenueTrackingAssetRecord
    func chalkingSnapshot(
        project: ProjectPackage,
        layout: FieldLayout,
        confidence: TrackingConfidence
    ) -> VenueTrackingSnapshot
}

enum DefaultARSessionCoordinatorFactory {
    static func make() -> ARSessionCoordinator {
        #if canImport(ARKit) && os(iOS)
        return ARKitSessionCoordinator()
        #else
        return MockARSessionCoordinator()
        #endif
    }
}

struct MockARSessionCoordinator: ARSessionCoordinator {
    private var sessionMode: ARSessionMode {
        .idle
    }

    func startPlanningSession(for venueScan: VenueScan) {}

    func startChalkingSession(for venueScan: VenueScan, assetData: Data?) {}

    func capturePlanningAsset(for venueScan: VenueScan) async -> (VenueTrackingAssetRecord, Data?) {
        (recordPlanningAsset(for: venueScan), nil)
    }

    func stopSession() {}

    func currentDiagnostics(
        for venueScan: VenueScan,
        asset: VenueTrackingAssetRecord?,
        payload: Data?
    ) -> ARSessionDiagnostics {
        let snapshot = planningSnapshot(for: venueScan)

        return ARSessionDiagnostics(
            mode: sessionMode,
            relocalizationState: snapshot.relocalizationState,
            readinessScore: snapshot.readinessScore,
            hasLocalAsset: asset != nil,
            payloadSizeBytes: payload?.count ?? 0,
            activeHint: snapshot.activeHint,
            lastErrorDescription: nil
        )
    }

    func planningSnapshot(for venueScan: VenueScan) -> VenueTrackingSnapshot {
        VenueTrackingSnapshot(
            venueScanID: venueScan.id,
            relocalizationState: planningState(for: venueScan.scanCoverageScore),
            readinessScore: venueScan.scanCoverageScore,
            activeHint: venueScan.recommendedRelocalizationHints.first
                ?? "Capture durable landmarks so the venue can relocalize reliably."
        )
    }

    func recordPlanningAsset(for venueScan: VenueScan) -> VenueTrackingAssetRecord {
        VenueTrackingAssetRecord(
            venueScanID: venueScan.id,
            localStorageKey: "mock-asset-\(venueScan.id.uuidString.lowercased())",
            readinessScore: venueScan.scanCoverageScore
        )
    }

    func chalkingSnapshot(
        project: ProjectPackage,
        layout: FieldLayout,
        confidence: TrackingConfidence
    ) -> VenueTrackingSnapshot {
        let state: RelocalizationState
        switch confidence {
        case .good:
            state = project.venueScan.scanCoverageScore >= 0.65 ? .localized : .limited
        case .warning:
            state = .limited
        case .recover:
            state = .scanning
        }

        let hint: String
        switch state {
        case .localized:
            hint = "Relocalized for \(layout.name). Keep the trolley moving steadily."
        case .limited:
            hint = "Tracking is partially constrained. Keep a known landmark edge in view when possible."
        case .scanning:
            hint = project.venueScan.recommendedRelocalizationHints.first
                ?? "Turn back toward a registered landmark edge to recover."
        case .unavailable:
            hint = "No venue tracking asset is available yet."
        }

        return VenueTrackingSnapshot(
            venueScanID: project.venueScan.id,
            relocalizationState: state,
            readinessScore: project.venueScan.scanCoverageScore,
            activeHint: hint
        )
    }

    private func planningState(for score: Double) -> RelocalizationState {
        switch score {
        case 0.7...:
            return .localized
        case 0.4...:
            return .limited
        default:
            return .scanning
        }
    }
}
