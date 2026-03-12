import SwiftUI
import ArmyraCore

struct ProjectsView: View {
    @ObservedObject var store: ProjectStore

    var body: some View {
        NavigationStack {
            Group {
                if store.projects.isEmpty {
                    ContentUnavailableView("No projects yet", systemImage: "square.stack")
                } else {
                    List {
                        Section("Projects") {
                            ForEach(store.projects) { project in
                                Button {
                                    store.selectProject(project.id)
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(project.projectName)
                                                .font(.headline)
                                            Spacer()
                                            if project.id == store.selectedProjectID {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.blue)
                                            }
                                        }

                                        Text(project.venueScan.venueName)
                                            .foregroundStyle(.secondary)
                                        Text("\(project.layouts.count) layouts, scan score \(Int(project.venueScan.scanCoverageScore * 100))%")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if let project = store.selectedProject {
                            Section("Selected Project") {
                                LabeledContent("Venue", value: project.venueScan.venueName)
                                LabeledContent("Templates", value: "\(project.templates.count)")
                                LabeledContent("Layouts", value: "\(project.layouts.count)")
                                LabeledContent("Suggested export", value: ProjectPackageStore.suggestedFileName(for: project))

                                Button("Duplicate Project") {
                                    store.duplicateSelectedProject()
                                }

                                Button("Preview Export Package") {
                                    store.showExportPreview()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Projects")
        }
    }
}
