import ArmyraCore

protocol VenueTrackingService {
    func startSession(project: ProjectPackage, layout: FieldLayout) -> ChalkingSessionState
    func advance(_ session: ChalkingSessionState, project: ProjectPackage, layout: FieldLayout) -> ChalkingSessionState
    func cycleConfidence(_ session: ChalkingSessionState, project: ProjectPackage, layout: FieldLayout) -> ChalkingSessionState
    func reconcile(
        _ session: ChalkingSessionState,
        project: ProjectPackage,
        layout: FieldLayout,
        trackingSnapshot: VenueTrackingSnapshot
    ) -> ChalkingSessionState
}

struct MockVenueTrackingService: VenueTrackingService {
    func startSession(project: ProjectPackage, layout: FieldLayout) -> ChalkingSessionState {
        let geometry = FieldGeometryBuilder.build(for: layout)
        let preflight = ChalkingGuidancePlanner.makePreflight(project: project, layout: layout)
        let hint = preflight.warning.map { "\(preflight.startHint) \($0)" } ?? preflight.startHint

        return ChalkingSessionState(
            layoutID: layout.id,
            layoutName: layout.name,
            completedSegments: 0,
            totalSegments: max(geometry.guidePath.count, 1),
            trackingConfidence: .good,
            recommendedHint: hint,
            guideSegments: geometry.guideSegments
        )
    }

    func advance(_ session: ChalkingSessionState, project: ProjectPackage, layout: FieldLayout) -> ChalkingSessionState {
        let geometry = FieldGeometryBuilder.build(for: layout)
        let totalSegments = max(geometry.guidePath.count, 1)
        let nextCompletedSegments = min(session.completedSegments + 1, totalSegments)

        return ChalkingSessionState(
            layoutID: layout.id,
            layoutName: layout.name,
            completedSegments: nextCompletedSegments,
            totalSegments: totalSegments,
            trackingConfidence: session.trackingConfidence,
            recommendedHint: guidanceHint(
                for: session.trackingConfidence,
                project: project,
                remainingSegments: max(totalSegments - nextCompletedSegments, 0)
            ),
            guideSegments: session.guideSegments
        )
    }

    func cycleConfidence(_ session: ChalkingSessionState, project: ProjectPackage, layout: FieldLayout) -> ChalkingSessionState {
        let nextConfidence: TrackingConfidence
        switch session.trackingConfidence {
        case .good:
            nextConfidence = .warning
        case .warning:
            nextConfidence = .recover
        case .recover:
            nextConfidence = .good
        }

        return ChalkingSessionState(
            layoutID: layout.id,
            layoutName: layout.name,
            completedSegments: session.completedSegments,
            totalSegments: session.totalSegments,
            trackingConfidence: nextConfidence,
            recommendedHint: guidanceHint(
                for: nextConfidence,
                project: project,
                remainingSegments: max(session.totalSegments - session.completedSegments, 0)
            ),
            guideSegments: session.guideSegments
        )
    }

    func reconcile(
        _ session: ChalkingSessionState,
        project: ProjectPackage,
        layout: FieldLayout,
        trackingSnapshot: VenueTrackingSnapshot
    ) -> ChalkingSessionState {
        let confidence: TrackingConfidence
        switch trackingSnapshot.relocalizationState {
        case .localized:
            confidence = .good
        case .limited:
            confidence = .warning
        case .scanning, .unavailable:
            confidence = .recover
        }

        let autoCompletedSegments: Int
        if confidence == .good && session.completedSegments < session.totalSegments {
            autoCompletedSegments = min(session.completedSegments + 1, session.totalSegments)
        } else {
            autoCompletedSegments = session.completedSegments
        }

        let remainingSegments = max(session.totalSegments - autoCompletedSegments, 0)
        let guidanceBase = guidanceHint(
            for: confidence,
            project: project,
            remainingSegments: remainingSegments
        )

        return ChalkingSessionState(
            layoutID: layout.id,
            layoutName: layout.name,
            completedSegments: autoCompletedSegments,
            totalSegments: session.totalSegments,
            trackingConfidence: confidence,
            recommendedHint: "\(trackingSnapshot.activeHint) \(guidanceBase)",
            guideSegments: session.guideSegments
        )
    }

    private func guidanceHint(
        for confidence: TrackingConfidence,
        project: ProjectPackage,
        remainingSegments: Int
    ) -> String {
        let recoveryHint = project.venueScan.recommendedRelocalizationHints.first ?? "Return to a known landmark edge."

        switch confidence {
        case .good:
            return remainingSegments == 0 ? "Layout complete. Review the line edges before saving." : "Tracking is stable. Continue to the next chalk segment."
        case .warning:
            return "Tracking is softening. Slow down and glance back toward the registered landmarks."
        case .recover:
            return "Pause chalking and relocalize. \(recoveryHint)"
        }
    }
}
