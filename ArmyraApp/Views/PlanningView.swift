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
                            templatePickerCard

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Saved Layouts")
                                    .font(.headline)

                                ForEach(project.layouts) { layout in
                                    let geometry = FieldGeometryBuilder.build(for: layout)

                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(layout.name)
                                                    .font(.title3.weight(.semibold))
                                                Text("\(Int(layout.dimensions.lengthMeters))m x \(Int(layout.dimensions.widthMeters))m")
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text(lockModeText(layout.lockMode))
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(.blue.opacity(0.12), in: Capsule())
                                        }

                                        Text(store.markingsDescription(for: layout))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)

                                        Text("Boundary: \(geometry.boundary.count), interior: \(geometry.interiorLines.count), circles: \(geometry.circles.count)")
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

    private var templatePickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Layout")
                .font(.headline)

            if let project = store.selectedProject {
                Picker("Template", selection: Binding(get: {
                    store.selectedTemplateID ?? project.templates.first?.id ?? UUID()
                }, set: { newValue in
                    store.selectedTemplateID = newValue
                })) {
                    ForEach(project.templates) { template in
                        Text(template.name).tag(template.id)
                    }
                }
                .pickerStyle(.segmented)

                if let template = store.selectedTemplate {
                    Text("Default markings: \(template.defaultMarkings.map(\.rawValue).sorted().joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    store.addLayoutFromSelectedTemplate()
                } label: {
                    Label("Add Layout From Template", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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