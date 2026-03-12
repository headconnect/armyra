import SwiftUI
import ArmyraCore

struct ChalkingView: View {
    @ObservedObject var store: ProjectStore

    var body: some View {
        NavigationStack {
            Group {
                if let project = store.selectedProject {
                    List {
                        Section("Choose Layout") {
                            ForEach(project.layouts) { layout in
                                Button {
                                    store.selectChalkingLayout(layout.id)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(layout.name)
                                                .font(.headline)
                                            Text(chalkingInstruction(for: layout, in: project))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        if store.selectedChalkingLayout?.id == layout.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if let layout = store.selectedChalkingLayout {
                            let preflight = ChalkingGuidancePlanner.makePreflight(project: project, layout: layout)

                            Section("Preflight") {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(layout.name)
                                            .font(.headline)
                                        Spacer()
                                        Text(readinessLabel(preflight.readinessLevel))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(readinessColor(preflight.readinessLevel))
                                    }

                                    Text(preflight.startHint)
                                        .font(.subheadline)

                                    Text(preflight.recoveryHint)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    if let snapshot = store.chalkingTrackingSnapshot {
                                        Label(store.chalkingRelocalizationLabel(), systemImage: "scope")
                                            .font(.subheadline.weight(.semibold))
                                        Text(snapshot.activeHint)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Label("No live relocalization yet", systemImage: "scope")
                                            .font(.subheadline.weight(.semibold))
                                        Text("Start the chalking session to simulate venue relocalization against the saved scan asset.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    DisclosureGroup("Diagnostics") {
                                        VStack(alignment: .leading, spacing: 8) {
                                            if let diagnostics = store.chalkingDiagnostics() {
                                                diagnosticsView(diagnostics)
                                            }

                                            if !store.chalkingDiagnosticsHistory.isEmpty {
                                                diagnosticsHistoryView(store.chalkingDiagnosticsHistory)
                                            }
                                        }
                                        .padding(.top, 6)
                                    }

                                    ForEach(preflight.checklist, id: \.self) { item in
                                        Label(item, systemImage: "checkmark.circle")
                                            .font(.subheadline)
                                    }

                                    if let warning = preflight.warning {
                                        Label(warning, systemImage: "exclamationmark.triangle.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }

                        if let session = store.chalkingSession {
                            Section("Active Session") {
                                VStack(alignment: .leading, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(store.chalkingOperationalStateLabel())
                                            .font(.title3.weight(.semibold))
                                            .foregroundStyle(confidenceColor(session.trackingConfidence))

                                        Text(store.chalkingOperationalStateDetail())
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(session.layoutName)
                                                .font(.headline)
                                            Text(confidenceLabel(session.trackingConfidence))
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(confidenceColor(session.trackingConfidence))
                                        }
                                        Spacer()
                                        Text("\(session.completedSegments)/\(session.totalSegments)")
                                            .font(.title3.monospacedDigit())
                                    }

                                    ProgressView(value: session.progressFraction)
                                        .tint(confidenceColor(session.trackingConfidence))

                                    ChalkPathPreviewView(
                                        guideSegments: session.guideSegments,
                                        activeSegmentID: session.currentSegment?.id,
                                        completedSegmentIDs: Set(session.guideSegments.prefix(session.completedSegments).map(\.id)),
                                        startPoint: store.chalkingStartPoint(),
                                        recoveryPoint: store.chalkingRecoveryPoint()
                                    )
                                    .frame(height: 220)

                                    HStack {
                                        Label("Start reference", systemImage: "flag.fill")
                                            .font(.caption)
                                            .foregroundStyle(.blue)

                                        if store.chalkingRecoveryPoint() != nil {
                                            Label("Recovery target", systemImage: "location.fill")
                                                .font(.caption)
                                                .foregroundStyle(.red)
                                        }
                                    }

                                    if let currentSegment = session.currentSegment {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Current Segment")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text(currentSegment.label)
                                                .font(.headline)
                                            Text(segmentKindLabel(currentSegment.kind))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    if !session.upcomingSegments.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Up Next")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)

                                            ForEach(session.upcomingSegments) { segment in
                                                Text(segment.label)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }

                                    Text(session.recommendedHint)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    if session.trackingConfidence != .good {
                                        Text("If the overlay stops feeling trustworthy, return to the red marker and face the strongest landmark side before resuming.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    HStack {
                                        Button("Refresh Live Status") {
                                            store.refreshChalkingTracking()
                                        }
                                        .buttonStyle(.borderedProminent)

                                        Button("Advance Segment") {
                                            store.advanceChalkingSession()
                                        }
                                        .buttonStyle(.bordered)

                                        Button("Simulate Drift") {
                                            store.cycleTrackingConfidence()
                                        }
                                        .buttonStyle(.bordered)
                                    }

                                    Text("Live status uses relocalization diagnostics when available. Manual controls remain here for simulator fallback and drift rehearsal.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Button("End Session", role: .destructive) {
                                        store.endChalkingSession()
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        } else {
                            Section("Session") {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("No chalking session is active.")
                                        .foregroundStyle(.secondary)

                                    Button("Start Chalking Session") {
                                        store.startChalkingSession()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(store.selectedChalkingLayout == nil)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("No pitch package loaded", systemImage: "square.and.arrow.down")
                }
            }
            .navigationTitle("Chalking")
        }
    }

    private func chalkingInstruction(for layout: FieldLayout, in project: ProjectPackage) -> String {
        let firstHint = project.venueScan.recommendedRelocalizationHints.first ?? "Start from a known landmark edge."
        return "Begin with the perimeter for \(layout.name). \(firstHint)"
    }

    private func confidenceLabel(_ confidence: TrackingConfidence) -> String {
        switch confidence {
        case .good:
            return "Tracking good"
        case .warning:
            return "Tracking warning"
        case .recover:
            return "Recovery needed"
        }
    }

    private func confidenceColor(_ confidence: TrackingConfidence) -> Color {
        switch confidence {
        case .good:
            return .green
        case .warning:
            return .orange
        case .recover:
            return .red
        }
    }

    private func readinessLabel(_ readinessLevel: VenueReadinessLevel) -> String {
        switch readinessLevel {
        case .high:
            return "High scan readiness"
        case .moderate:
            return "Moderate scan readiness"
        case .low:
            return "Low scan readiness"
        }
    }

    private func readinessColor(_ readinessLevel: VenueReadinessLevel) -> Color {
        switch readinessLevel {
        case .high:
            return .green
        case .moderate:
            return .orange
        case .low:
            return .red
        }
    }

    private func segmentKindLabel(_ kind: GuideSegmentKind) -> String {
        switch kind {
        case .boundary:
            return "Boundary line"
        case .interior:
            return "Interior marking"
        }
    }

    @ViewBuilder
    private func diagnosticsView(_ diagnostics: ARSessionDiagnostics) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Diagnostics")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Mode: \(diagnostics.mode.rawValue.capitalized)")
                .font(.caption)
            Text("Payload: \(diagnostics.payloadSizeBytes) bytes")
                .font(.caption)
            Text("Asset saved: \(diagnostics.hasLocalAsset ? "yes" : "no")")
                .font(.caption)

            if let lastErrorDescription = diagnostics.lastErrorDescription {
                Text("Last error: \(lastErrorDescription)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private func diagnosticsHistoryView(_ events: [ARDiagnosticsEvent]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent events")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(events.reversed()) { event in
                Text(historyLine(for: event))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func historyLine(for event: ARDiagnosticsEvent) -> String {
        let time = event.timestamp.formatted(date: .omitted, time: .shortened)
        let readiness = Int((event.diagnostics.readinessScore * 100).rounded())
        return "\(time) - \(event.kind.rawValue) - \(event.diagnostics.relocalizationState.rawValue) - \(readiness)%"
    }
}
