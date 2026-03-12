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

                        if let session = store.chalkingSession {
                            Section("Active Session") {
                                VStack(alignment: .leading, spacing: 12) {
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

                                    Text(session.recommendedHint)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    HStack {
                                        Button("Advance Segment") {
                                            store.advanceChalkingSession()
                                        }
                                        .buttonStyle(.borderedProminent)

                                        Button("Cycle Confidence") {
                                            store.cycleTrackingConfidence()
                                        }
                                        .buttonStyle(.bordered)
                                    }

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
}
