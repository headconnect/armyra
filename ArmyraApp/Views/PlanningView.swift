import SwiftUI
import ArmyraCore

struct PlanningView: View {
    @ObservedObject var store: ProjectStore

    var body: some View {
        NavigationStack {
            Group {
                if let project = store.selectedProject {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            summaryCard(for: project)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Saved Layouts")
                                    .font(.headline)

                                ForEach(project.layouts) { layout in
                                    let geometry = FieldGeometryBuilder.build(for: layout)

                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(layout.name)
                                                .font(.title3.weight(.semibold))
                                            Spacer()
                                            Text(lockModeText(layout.lockMode))
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(.blue.opacity(0.12), in: Capsule())
                                        }

                                        Text("\(Int(layout.dimensions.lengthMeters))m x \(Int(layout.dimensions.widthMeters))m")
                                            .foregroundStyle(.secondary)

                                        Text("Boundary segments: \(geometry.boundary.count), interior segments: \(geometry.interiorLines.count), circular marks: \(geometry.circles.count)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView("No project selected", systemImage: "tray")
                }
            }
            .navigationTitle("Planning")
        }
    }

    private func summaryCard(for project: ProjectPackage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Venue Scan")
                .font(.headline)

            Text("\(project.venueScan.venueName) has \(project.venueScan.landmarkNotes.count) landmark notes and \(project.venueScan.recommendedRelocalizationHints.count) recovery hints.")
                .foregroundStyle(.secondary)

            ForEach(project.venueScan.landmarkNotes, id: \.self) { note in
                Label(note, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func lockModeText(_ lockMode: PlacementLockMode) -> String {
        switch lockMode {
        case .center:
            return "Center lock"
        case .corner(let corner):
            return "\(corner.rawValue) lock"
        }
    }
}