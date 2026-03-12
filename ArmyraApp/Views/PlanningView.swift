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
                            selectedLayoutInspector

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Saved Layouts")
                                    .font(.headline)

                                ForEach(project.layouts) { layout in
                                    let geometry = FieldGeometryBuilder.build(for: layout)

                                    Button {
                                        store.selectLayout(layout.id)
                                    } label: {
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
                                        .background(backgroundStyle(for: layout), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
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

    private var selectedLayoutInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Layout")
                .font(.headline)

            if let layout = store.selectedLayout {
                TextField(
                    "Layout name",
                    text: Binding(
                        get: { layout.name },
                        set: { store.updateSelectedLayoutName($0) }
                    )
                )
                .textFieldStyle(.roundedBorder)

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Length")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Stepper(
                            "\(Int(layout.dimensions.lengthMeters)) m",
                            value: Binding(
                                get: { layout.dimensions.lengthMeters },
                                set: { store.updateSelectedLayoutLength($0) }
                            ),
                            in: 1...140,
                            step: 1
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Width")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Stepper(
                            "\(Int(layout.dimensions.widthMeters)) m",
                            value: Binding(
                                get: { layout.dimensions.widthMeters },
                                set: { store.updateSelectedLayoutWidth($0) }
                            ),
                            in: 1...100,
                            step: 1
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Rotation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(store.selectedLayoutRotationDegrees())) deg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { store.selectedLayoutRotationDegrees() },
                            set: { store.updateSelectedLayoutRotationDegrees($0) }
                        ),
                        in: -180...180,
                        step: 1
                    )
                }

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Offset X")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Stepper(
                            "\(Int(layout.transform.translation.dx)) m",
                            value: Binding(
                                get: { layout.transform.translation.dx },
                                set: { store.updateSelectedLayoutOffsetX($0) }
                            ),
                            in: -150...150,
                            step: 1
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Offset Y")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Stepper(
                            "\(Int(layout.transform.translation.dy)) m",
                            value: Binding(
                                get: { layout.transform.translation.dy },
                                set: { store.updateSelectedLayoutOffsetY($0) }
                            ),
                            in: -150...150,
                            step: 1
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Lock Mode")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    lockModeButtons
                }
            } else {
                Text("Pick a layout card below to edit its placement and dimensions.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

    private var lockModeButtons: some View {
        let options: [(String, PlacementLockMode)] = [
            ("Center", .center),
            ("Top Left", .corner(.topLeft)),
            ("Top Right", .corner(.topRight)),
            ("Bottom Left", .corner(.bottomLeft)),
            ("Bottom Right", .corner(.bottomRight)),
        ]

        return VStack(alignment: .leading, spacing: 8) {
            ForEach(options, id: \.0) { label, mode in
                Button {
                    store.updateSelectedLayoutLockMode(mode)
                } label: {
                    HStack {
                        Text(label)
                        Spacer()
                        if store.selectedLayout?.lockMode == mode {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
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

    private func backgroundStyle(for layout: FieldLayout) -> AnyShapeStyle {
        if store.selectedLayout?.id == layout.id {
            return AnyShapeStyle(.blue.opacity(0.16))
        }

        return AnyShapeStyle(.thinMaterial)
    }
}
