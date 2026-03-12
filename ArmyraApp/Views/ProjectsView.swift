import SwiftUI
import ArmyraCore

struct ProjectsView: View {
    @ObservedObject var store: ProjectStore

    var body: some View {
        NavigationStack {
            List(store.projects, id: \.id, selection: $store.selectedProjectID) { project in
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.projectName)
                        .font(.headline)
                    Text(project.venueScan.venueName)
                        .foregroundStyle(.secondary)
                    Text("\(project.layouts.count) layouts, scan score \(Int(project.venueScan.scanCoverageScore * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Projects")
        }
    }
}