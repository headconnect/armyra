import SwiftUI

struct RootView: View {
    @ObservedObject var store: ProjectStore
    @State private var isExportingDocument = false
    @State private var isImportingDocument = false

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
        .fileExporter(
            isPresented: $isExportingDocument,
            document: store.exportDocument,
            contentType: .armyraField,
            defaultFilename: store.exportDocument.map { ProjectPackageStore.suggestedFileName(for: $0.project) }
        ) { _ in
            store.exportDocument = nil
        }
        .fileImporter(
            isPresented: $isImportingDocument,
            allowedContentTypes: [.armyraField, .json]
        ) { result in
            switch result {
            case .success(let url):
                do {
                    let data = try Data(contentsOf: url)
                    let project = try ProjectPackageStore.decode(data)
                    store.importProject(from: ProjectPackageDocument(project: project))
                } catch {
                    store.handleImportFailure(error)
                }
            case .failure(let error):
                store.handleImportFailure(error)
            }
        }
        .alert("Import failed", isPresented: Binding(
            get: { store.importErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    store.dismissImportError()
                }
            }
        )) {
            Button("OK", role: .cancel) {
                store.dismissImportError()
            }
        } message: {
            Text(store.importErrorMessage ?? "Unknown import error.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Import") {
                    isImportingDocument = true
                }

                Button("Export") {
                    store.prepareExportDocument()
                    isExportingDocument = true
                }
                .disabled(store.selectedProject == nil)
            }
        }
    }
}
