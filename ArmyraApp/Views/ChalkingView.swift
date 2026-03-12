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
                                Text("Ready")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.green)
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
}