import SwiftUI

struct RootView: View {
    @ObservedObject var store: ProjectStore

    var body: some View {
        TabView {
            ProjectsView(store: store)
                .tabItem {
                    Label("Projects", systemImage: "square.grid.2x2")
                }

            PlanningView(store: store)
                .tabItem {
                    Label("Planning", systemImage: "ruler")
                }

            ChalkingView(store: store)
                .tabItem {
                    Label("Chalking", systemImage: "figure.walk")
                }
        }
        .sheet(item: $store.exportPreview) { preview in
            NavigationStack {
                ScrollView {
                    Text(preview.payload)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .navigationTitle(preview.fileName)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            store.dismissExportPreview()
                        }
                    }
                }
            }
        }
    }
}