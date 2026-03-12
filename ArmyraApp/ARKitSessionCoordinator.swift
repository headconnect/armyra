#if canImport(ARKit) && os(iOS)
import ARKit
import Foundation
import ArmyraCore

final class ARKitSessionCoordinator: NSObject, ARSessionCoordinator, ARSessionDelegate {
    private let session = ARSession()
    private let fallback = MockARSessionCoordinator()

    override init() {
        super.init()
        session.delegate = self
    }

    func startPlanningSession(for venueScan: VenueScan) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.worldAlignment = .gravity
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func startChalkingSession(for venueScan: VenueScan, assetData: Data?) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity

        if let assetData,
           let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: assetData) {
            configuration.initialWorldMap = worldMap
        }

        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func capturePlanningAsset(for venueScan: VenueScan) async -> (VenueTrackingAssetRecord, Data?) {
        await withCheckedContinuation { continuation in
            session.getCurrentWorldMap { worldMap, _ in
                let record = self.recordPlanningAsset(for: venueScan)

                guard let worldMap,
                      let data = try? NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true) else {
                    continuation.resume(returning: (record, nil))
                    return
                }

                continuation.resume(returning: (record, data))
            }
        }
    }

    func stopSession() {
        session.pause()
    }

    func planningSnapshot(for venueScan: VenueScan) -> VenueTrackingSnapshot {
        let fallbackSnapshot = fallback.planningSnapshot(for: venueScan)
        guard let frame = session.currentFrame else {
            return fallbackSnapshot
        }

        return VenueTrackingSnapshot(
            venueScanID: venueScan.id,
            relocalizationState: relocalizationState(
                worldMappingStatus: frame.worldMappingStatus,
                trackingState: frame.camera.trackingState
            ),
            readinessScore: max(venueScan.scanCoverageScore, mappingScore(for: frame.worldMappingStatus)),
            activeHint: mappingHint(for: frame.worldMappingStatus, fallback: fallbackSnapshot.activeHint)
        )
    }

    func recordPlanningAsset(for venueScan: VenueScan) -> VenueTrackingAssetRecord {
        let fallbackAsset = fallback.recordPlanningAsset(for: venueScan)
        let worldMapKey = "arkit-worldmap-\(venueScan.id.uuidString.lowercased())"

        return VenueTrackingAssetRecord(
            id: fallbackAsset.id,
            venueScanID: venueScan.id,
            localStorageKey: worldMapKey,
            readinessScore: fallbackAsset.readinessScore
        )
    }

    func chalkingSnapshot(
        project: ProjectPackage,
        layout: FieldLayout,
        confidence: TrackingConfidence
    ) -> VenueTrackingSnapshot {
        let fallbackSnapshot = fallback.chalkingSnapshot(project: project, layout: layout, confidence: confidence)
        guard let frame = session.currentFrame else {
            return fallbackSnapshot
        }

        return VenueTrackingSnapshot(
            venueScanID: project.venueScan.id,
            relocalizationState: relocalizationState(
                worldMappingStatus: frame.worldMappingStatus,
                trackingState: frame.camera.trackingState
            ),
            readinessScore: max(project.venueScan.scanCoverageScore, mappingScore(for: frame.worldMappingStatus)),
            activeHint: mappingHint(
                for: frame.worldMappingStatus,
                trackingState: frame.camera.trackingState,
                layoutName: layout.name,
                fallback: fallbackSnapshot.activeHint
            )
        )
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Placeholder for future error surfacing once the AR session is wired into the UI.
        print("ARSession failed: \(error.localizedDescription)")
    }

    private func relocalizationState(
        worldMappingStatus: ARFrame.WorldMappingStatus,
        trackingState: ARCamera.TrackingState
    ) -> RelocalizationState {
        switch trackingState {
        case .notAvailable:
            return .unavailable
        case .limited:
            return .scanning
        case .normal:
            switch worldMappingStatus {
            case .mapped, .extending:
                return .localized
            case .limited:
                return .limited
            case .notAvailable:
                return .scanning
            @unknown default:
                return .limited
            }
        }
    }

    private func mappingScore(for status: ARFrame.WorldMappingStatus) -> Double {
        switch status {
        case .notAvailable:
            return 0.2
        case .limited:
            return 0.45
        case .extending:
            return 0.72
        case .mapped:
            return 0.9
        @unknown default:
            return 0.5
        }
    }

    private func mappingHint(for status: ARFrame.WorldMappingStatus, fallback: String) -> String {
        switch status {
        case .notAvailable:
            return "Move the phone to capture more stable visual features around the venue."
        case .limited:
            return "ARKit is finding some structure, but more landmark coverage is still needed."
        case .extending:
            return "The world map is extending. Walk the venue boundary to improve relocalization."
        case .mapped:
            return fallback
        @unknown default:
            return fallback
        }
    }

    private func mappingHint(
        for status: ARFrame.WorldMappingStatus,
        trackingState: ARCamera.TrackingState,
        layoutName: String,
        fallback: String
    ) -> String {
        switch trackingState {
        case .notAvailable:
            return "AR tracking is not available yet. Re-aim the phone toward saved landmarks before chalking \(layoutName)."
        case .limited(let reason):
            return "Tracking is limited (\(reasonDescription(reason))). Slow down and re-aim toward known landmarks."
        case .normal:
            return mappingHint(for: status, fallback: fallback)
        }
    }

    private func reasonDescription(_ reason: ARCamera.TrackingState.Reason) -> String {
        switch reason {
        case .initializing:
            return "initializing"
        case .excessiveMotion:
            return "excessive motion"
        case .insufficientFeatures:
            return "insufficient features"
        case .relocalizing:
            return "relocalizing"
        @unknown default:
            return "unknown"
        }
    }
}
#endif
