import SwiftUI
import ArmyraCore

struct ChalkingView: View {
    @ObservedObject var store: ProjectStore

    var body: some View {
        NavigationStack {
            Group {
                if let project = store.selectedProject {
                    List(project.layouts) { layout in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(layout.name)
                                    .font(.headline)
                                Spacer()
                                Text(statusText(for: layout))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(statusColor(for: layout))
                            }

                            Text(chalkingInstruction(for: layout, in: project))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
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

    private func statusText(for layout: FieldLayout) -> String {
        switch layout.lockMode {
        case .center:
            return "Relocalize"
        case .corner:
            return "Ready"
        }
    }

    private func statusColor(for layout: FieldLayout) -> Color {
        switch layout.lockMode {
        case .center:
            return .orange
        case .corner:
            return .green
        }
    }
}