import SwiftUI
import ArmyraCore

enum RootTab: Hashable {
    case projects
    case planning
    case chalking
}

struct RootView: View {
    @ObservedObject var store: ProjectStore
    let initialTab: RootTab
    @State private var isExportingDocument = false
    @State private var isImportingDocument = false
    @State private var selectedTab: RootTab

    init(store: ProjectStore, initialTab: RootTab = .projects) {
        self.store = store
        self.initialTab = initialTab
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ProjectsView(store: store)
                .tag(RootTab.projects)
                .tabItem {
                    Label("Projects", systemImage: "square.grid.2x2")
                }

            PlanningView(store: store)
                .tag(RootTab.planning)
                .tabItem {
                    Label("Planning", systemImage: "ruler")
                }

            ChalkingView(store: store)
                .tag(RootTab.chalking)
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
            if selectedTab == .projects {
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
}
